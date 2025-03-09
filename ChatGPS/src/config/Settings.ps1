#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptions.IncludeFields = $true

$LastUsedSettingsPath = $null
$LastSettingsJson = $null
$LastSettings = $null

$SettingsInitialized = $false


# These class definitions represent the deserialized structure of the
# configuration file. Using PowerShell classes here to generate a native
# .Net type allows us to use a type-aware serializer like System.Text.Json
# for reliable and safe consumption of the settings file.

class RootSettings {
    [string]$generatedDate
    [string]$generatedTool
    [string]$lastUpdatedDate
    [string]$lastUpdatedTool
    [string]$defaultProfile
    [ProfileSettings]$profiles
    [SessionSettings]$sessions
    [ModelResourceSettings]$models
}

class Profile {
    [string]$name
    [string]$sessionName
}

class ProfileSettings {
    [System.Collections.Generic.List[Profile]]$list
    [Profile]$defaults
}

class ModelChatSession {
    ModelChatSession() {
        $this.tokenLimit = $null
        $this.signinInteractionAllowed = $null
        $this.apikey= $null
        $this.noProxy = $null
        $this.forceProxy = $null
        $this.plainTextApiKey = $null
    }
    [string] $name
    [string] $modelName
    [string] $systemPromptId
    [string] $customSystemPrompt
    [string] $apiKey
    [string] $sendBlock
    [string] $receiveBlock
    [bool] $noProxy
    [bool] $forceProxy
    [int] $tokenLimit
    [string] $tokenStrategy
    [int] $historyContextLimit
    [bool] $signinInteractionAllowed
    [bool] $plainTextApiKey
    [string] $logDirectory
    [string] $logLevel
}


class SessionSettings {
    [System.Collections.Generic.List[ModelChatSession]]$list
    [ModelChatSession]$defaults
}

class ModelResource {
    [string] $name
    [string] $provider
    [Uri] $apiEndpoint
    [string] $localModelPath
    [string] $modelIdentifier
    [string] $deploymentName
}

class ModelResourceSettings {
    [System.Collections.Generic.List[ModelResource]] $list
}

function GetDefaultSettingsLocation {
    if ( ! $env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE ) {
        "~/.chatgps/settings.json"
    } else {
        write-verbose "The default settings path has been overridden by the environment variable CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE. The resulting value is '$($env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE)'"
        $env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE
    }
}

function InitializeCurrentSettings([string] $settingsPath = $null) {
    $isInitialized = $script:SettingsInitialized

    $script:SettingsInitialized = $true

    $targetPath = if ( $isInitialized -or ! ( $env:CHATGPS_SKIP_SETTINGS_ON_LOAD -eq $true ) ) {
        if ( $settingsPath ) {
            $settingsPath
        } else {
            GetDefaultSettingsLocation
        }
    }

    write-verbose "Resulting settings configuration path is '$settingsPath'. If the path is empty then initialization was skipped by environment variable."

    $settingsJson = if ( $targetPath -and ( test-path $targetPath ) ) {
        try {
            Get-Content $targetPath -raw
        } catch {
            write-warning "An error was encountered accessing the settings path '$targetPath'; settings configuration will be skipped and default settings will be used. The error was $($_.exception.message)"
        }
    }

    if ( $settingsJson ) {
        $typedSettings = SettingsJsonToStrongTypedSettings $settingsJson $targetPath

        # Need untyped settings here because we want unspecified values to
        # show up as null -- distinction is crucial for integer and boolean
        # types for instance.
        $untypedSettings = SettingsJsonToUntypedSettings $settingsJson

        $sessions = GetSessionSettingsFromSettings $untypedSettings

        $currentProfile = GetConfiguredProfileFromSettings $typedSettings

        $currentSession = if ( $sessions ) {
            $targetName = ( $currentProfile -and $currentProfile.sessionName ?
                            ($currentProfile.sessionName | select-object -first 1) :
                            $typedSettings.profiles.defaults.sessionName )

            if ( $targetName ) {
                $targetSession = $sessions | where-object name -eq $targetName | select-object -first 1

                if ( $targetSession ) {
                    $targetSession
                } else {
                    write-warning "Unable to set the current session to the specified session '$($currentProfile.sessionName)' because no such setting could be found."
                }
            }
        }

        if ( $currentSession ) {
            try {
                SetCurrentSession $currentSession
            } catch {
                write-warning "Unable to set current session to '$($currentSession.Name)' as specified by the configuration file; the file format may be incorrect. The error was $($_.exception)."
            }
        }

        $script:LastUsedSettingsPath = $targetPath
        $script:LastSettingsJson = $settingsJson
        $script:LastSettings = $typedSettings

    } else {
        write-verbose "Settings already initialized = $isInitialized; env var CHATGPS_SKIP_SETTINGS_ON_LOAD = $($env:CHATGPS_SKIP_SETTINGS_ON_LOAD)"
        write-verbose "Configured settings path not found or inaccessible, settings initialization will be skipped."
    }
}

function SettingsJsonToUntypedSettings([string] $settingsJson) {
    # Use the PowerShell deserializer -- it does not convert to a strong type,
    # hence unspecified values are not serialized at all, and this avoids
    # types such as integer or boolean from being set to default values that cannot
    # be distinguished from not being specified. Could also use System.Text.Json
    # without a type, but this is native to PowerShell...
    $settingsJson | ConvertFrom-Json
}

function SettingsJsonToStrongTypedSettings([string] $settingsJson, [string] $settingsSource) {
    try {
        [System.Text.Json.JsonSerializer]::Deserialize[RootSettings]($settingsJson, $jsonOptions)
    } catch {
        write-warning "The settings at location '$settingsSource' are incorrectly formatted. The following error was encountered reading the data: $($_.Exception.Message)"
    }
}

function GetModelResourcesFromSettings($settings) {
    if ( $settings | get-member models ) {
        $settings.models.list
    }
}

function GetExplicitSessionSettingsFromSettingsByName($settings, $sessionName) {
    $sessionSettings = $settings.sessions.list | where-object name -eq $sessionName

    $modelSettings = if ( $sessionSettings ) {
        GetExplicitModelSettingsFromSettingsByName $settings $sessionSettings.modelName
    }

    if ( $sessionSettings ) {
        [PSCustomObject] @{
            Session = $sessionSettings
            Model = $modelSettings
        }
    }
}

function GetExplicitModelSettingsFromSettingsByName($settings, $modelName) {
    if ( $settings.models.list ) {
        $settings.models.list | where-object name -eq $modelName
    }
}

function GetExplicitSessionSettingsFromSessionParameters($session, $settings) {
    $sessionSettings = [ModelChatSession]::new()
    $modelSettings = [ModelResource]::new()

    $sessionParameters = GetSessionCreationParameters $session

    if ( ! $sessionParameters ) {
        throw [ArgumentException]::new('The specified session does not contain configuration information')
    }

    $generatedName = "$([DateTimeOffset]::now.tostring('d'))-$($session.Id)"

    $sessionSettings.name = if ( $session.Name ) {
        $Session.Name
    } else {
        $generatedName
    }


    $sessionSettings.modelName = GetExplicitModelSettingsFromSettingsByName $settings $sessionSettings.modelName

    if ( ! $sessionSettings.modelName ) {
        $sessionSettings.modelName = "Model $($generatedName)"
    }

    'apiKey', 'systemPromptId', 'customSystemPrompt', 'tokenLimit', 'tokenStrategy', 'historyContextLimit', 'logDirectory', 'logLevel' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
        $sessionSettings.$_ = $sessionParameters[$_]
    }

    'noProxy', 'forceProxy', 'signinInteractionAllowed', 'plainTextApiKey' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
        $sessionSettings.$_ = $sessionParameters[$_].IsPresent
    }

    'sendblock', 'receiveBlock' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
        $sessionSettings.$_ = $sessionParameters[$_].ToString
      }

    if ( ! $sessionSettings.apiKey -and $session.CustomContext['AiOptions'] ) {
        $sessionSettings.apiKey = $session.CustomContext['AiOptions'].ApiKey
    }

    $hasModel = ( $null -ne $sessionSettings.modelName ) -and ( GetExplicitModelSettingsFromSettingsByName $settings $sessionSettings.modelName )

    $modelSettings = $null

    if ( ! $hasModel ) {
        $modelSettings = [ModelResource]::new()
        $modelSettings.Name = $sessionSettings.modelName
        $modelSettings.provider = $session.AiOptions.Provider
        $modelSettings.apiEndpoint = $session.AiOptions.ApiEndpoint
        $modelSettings.localModelPath = $session.AiOptions.LocalModelPath
        $modelSettings.modelIdentifier = $session.AiOptions.ModelIdentifier
        $modelSettings.deploymentName = $session.AiOptions.DeploymentName
    }

    [PSCustomObject] @{
        Session = $sessionSettings
        Model = $modelSettings
    }
}

function GetSessionSettingsFromSettings($settings) {
    $defaultSessionValues = $null

    $sessionList = if ( $settings.sessions ) {
        $defaultSessionValues = $settings.sessions.defaults
        $settings.sessions.list
    }

    $models = GetModelResourcesFromSettings $settings

    if ( $models ) {
        foreach ( $sessionSetting in $sessionList ) {
            SessionSettingToSession $sessionSetting $defaultSessionValues $models
        }
    } else {
        if ( $sessionList ) {
            write-warning "Ignoring session settings because no models were specified in the settings."
        }
    }
}

function SessionSettingToSession($sessionSetting, $defaultValues, $models) {
    $sourceSetting = [ModelChatSession]::new()

    $members = ($sourceSetting | Get-Member -MemberType Property).Name

    foreach ( $member in $members ) {
        if ( $sessionSetting | get-member $member ) {
            $sourceSetting.$member = $sessionSetting.$member
        } elseif ( $defaultValues ) {
            if ( $defaultValues | get-member $member ) {
                $sourceSetting.$member = $defaultValues.$member
            }
        }
    }

    $sessionParameters = @{
        Name = $sourceSetting.name
        AllowInteractiveSignin = [System.Management.Automation.SwitchParameter]::new($sourceSetting.signinInteractionAllowed)
    }

    $isValidSetting = if ( $null -eq $sourceSetting.name ) {
        write-warning "Skipping a session setting from the settings configuration because it is missing the required 'name' property."
        $false
    } elseif ( $null -eq $sourceSetting.modelName ) {
        write-warning "Skipping a session setting from the settings configuration because it is missing the required 'modelName' property."
        $false
    } else {
        $true
    }

    if ( $isValidSetting ) {
        $model = $models | where-object name -eq $sourceSetting.modelName

        if ( $model ) {
            'forceProxy', 'noProxy' | foreach {
                if ( $model | get-member $_ ) {
                    $sessionParameters.Add($_, [System.Management.Automation.SwitchParameter]::new($model.$_))
                }
            }

            'modelIdentifier', 'provider', 'apiEndpoint', 'localModelPath', 'deploymentName' | foreach {
                $value = if ( $model | get-member $_ ) {
                    # Yes, you must have empty string on the LHS because 0 -eq '' is true (???) but '' -eq 0 is false :(
                    '' -ne $model.$_ ? $model.$_ : $null
                }

                if ( $null -ne $value ) {
                    $sessionParameters.Add($_, $value)
                }
            }

            'receiveBlock', 'sendBlock' | foreach {
                $scriptBlock = if ( $_ -and $sourceSetting.$_ ) {
                    try {
                        [ScriptBlock]::Create($sourceSetting.$_)
                    } catch {
                        write-warning "Ignoring session field '$_' for session setting '$($sessionParameters.name)' because it is not a valid PowerShell script block -- please check the syntax and otherwise correct it."
                    }
                }

                if ( $scriptBlock ) {
                    $sessionParameters.Add($_, $scriptBlock)
                }
            }

        } else {
            $isValidSetting = $false
        }
    }

    if ( $isValidSetting ) {
        'systemPromptId', 'customSystemPrompt', 'logLevel', 'logDirectory', 'historyContextLimit', 'apiKey', 'tokenLimit' | foreach {
            # Yes, you must have empty string on the LHS because 0 -eq '' is true (???) but '' -eq 0 is false :(
            $value = '' -ne $sourceSetting.$_ ? $sourceSetting.$_ : $null

            if ( $null -ne $value ) {
                $sessionParameters.Add($_, $value)
            }
        }

        if ( $sessionParameters.ContainsKey('apiKey') ) {
            $sessionParameters.Add('plainTextApiKey', [System.Management.Automation.SwitchParameter]::new($sourceSetting.plainTextApiKey))
        }

        try {
            $newSession = Connect-ChatSession @sessionParameters -NoSetCurrent -NoConnect -PassThru -Force
            BindSettingsToSession $newSession $sourceSetting $model
            $newSession
        } catch {
            write-warning "Skipping incorrectly specified session setting '$($sourceSetting.Name)'. The following error was encountered: $($_.exception.message)"
        }
    } else {
        write-warning "Skipping session setting '$($sourceSetting.Name)' because it was incorrectly specified"
    }
}

function BindSettingsToSession([Modulus.ChatGPS.Models.ChatSession] $session, $sessionSetting, $modelSetting) {
    UpdateSession $session ([PSCustomObject] @{
                                Session = $sessionSetting
                                Model = $modelSetting
                            })
}

function GetSettingsFromSession($session) {
    GetSessionSettingsInfo $session
}

function GetConfiguredProfileFromSettings([RootSettings] $settings) {
    if ( $settings ) {
        if ( ( $settings | get-member defaultProfile ) -and $settings.defaultProfile -and $settings.profiles -and $settings.profiles.list ) {
            $settings.profiles.list | where-object name -eq $settings.defaultProfile
        }
    }
}

function GetLastSettingsPath {
    $script:LastUsedSettingsPath
}

function GetLastSettings {
    if ( $script:LastSettingsJson ) {
        $script:LastSettingsJson | convertfrom-json
    }
}

function GetSettingIndex($settingCollection, [string] $settingName) {
    $result = -1

    if ( $settingCollection -and $settingCollection.list ) {
        for ( $current = 0; $current -lt $settingCollection.list.count; $current++ ) {
            if ( $settingCollection.list[$current] -eq $settingName ) {
                $result = $current
                break
            }
        }
    }

    $result
}

function GetSessionSettingIndex([RootSettings] $settings, [string] $sessionName) {
    GetSettingIndex $settings.sessions $sessionName
}

function GetModelSettingIndex([RootSettings] $settings, [string] $modelName) {
    GetSettingIndex $settings.models $SmodelName
}

function UpdateModelSetting([RootSettings] $settings, [int] $modelIndex, [ModelResource] $modelSetting) {
    if ( $null -eq $settings.models.list ) {
        $settings.models.list = [System.Collections.Generic.List[ModelResource]]::new()
    }

    if ( $modelIndex -ne -1 ) {
        $settings.models.list[$modelIndex] = $modelSetting
    } else {
        $settings.models.list.Add($modelSetting)
    }
}

function UpdateSessionSetting([RootSettings] $settings, [int] $sessionIndex, [ModelChatSession] $sessionSetting, [string] $profileToUpdate = $null, [bool] $noCreateMissingProfile, [bool] $setDefaultProfile, [bool] $setDefaultSession) {
    if ( $null -eq $settings.sessions.list ) {
        $settings.sessions.list = [System.Collections.Generic.List[ModelChatSession]]::new()
    }

    if ( $sessionIndex -ne -1 ) {
        $settings.sessions.list[$sessionIndex] = $sessionSetting
    } else {
        $sessionIndex = $settings.sessions.list.count
        $settings.sessions.list.Add($sessionSetting)
    }

    $profileIndex = -1

    $namedProfile = if ( $profileToUpdate ) {
        for ( $current = 0; $current -lt $settings.profiles.list.count; $current++ ) {
            if ( $settings.profiles.list[$current].Name -eq $profileToUpdate ) {
                $profileIndex = $current
                $settings.profiles.list[$profileIndex]
                break
            }
        }
    }

    $targetProfile = if ( $namedProfile ) {
        $namedProfile
    } elseif ( ! $noCreateMissingProfile ) {
        if ( ! $profileToUpdate -and $settings.profiles.list.count -eq 0 ) {
            # Only create a default profile no profile was specified AND there are no profiles
            NewProfile $profileToUpdate $sessionSetting.name
        }
    } elseif ( $profileToUpdate) {
        write-warning "The specified profile '$profileToUpdate' did not exist and automatic profile creation is disabled, so this non-existent profile's session key will not be configured."
    }

    if ( $targetProfile ) {
        if ( $profileIndex -eq -1 ) {
            $settings.profiles.list.Add($targetProfile)

            if ( $setDefaultProfile ) {
                $settings.defaultProfile = $targetProfile.name
            }
        } else {
            $settings.profiles.list[$profileIndex] = $targetProfile
        }
    }

    if ( $setDefaultSession ) {
        $settings.profiles.defaults.sessionName = $sessionSetting.Name
    }
}

function NewProfile([string] $profileName = $null, [string] $sessionName = $null) {
    $newProfile = [Profile]::new()
    $newProfile.name = !! $profileName ? $profileName : 'Profile0'
    $newProfile.sessionName = $sessionName
    $newProfile
}

function WriteSettings([RootSettings] $settings, [string] $settingsPath, [bool] $noWrite) {
    $settings.lastUpdatedDate = [DateTimeOFfset]::now.ToString()
    $settings.lastUpdatedTool = 'ChatGPS Save-ChatSettings'

    if ( ! $noWrite ) {
        $settings | convertto-json -depth 5 | set-content -encoding utf8 -path $settingsPath
    } else {
        $settings
    }
}
