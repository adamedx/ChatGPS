#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptions.IncludeFields = $true

$LastUsedSettingsPath = $null
$LastSettingsJson = $null

$SettingsInitialized = $false


# These class definitions represent the deserialized structure of the
# configuration file. Using PowerShell classes here to generate a native
# .Net type allows us to use a type-aware serializer like System.Text.Json
# for reliable and safe consumption of the settings file.

class RootSettings {
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
    [Profile[]]$list
    [Profile]$defaults
}

class ModelChatSession {
    ModelChatSession() {
        $this.tokenLimit = $null
        $this.signinInteractionAllowed = $null
        $this.apiEndpoint = $null
        $this.apikey= $null
    }
    [string]$name
    [string]$modelName
    [string]$provider
    [Uri] $apiEndpoint
    [string] $apiKey
    [string] $localModelPath
    [string] $modelIdentifier
    [string] $deploymentName
    [int] $tokenLimit
    [bool] $signinInteractionAllowed
    [bool] $plainTextApiKey
}


class SessionSettings {
    [ModelChatSession[]]$list
    [ModelChatSession]$defaults
}

class ModelResource {
    [string] $name
    [string] $provider
    [Uri] $apiEndpoint
    [string] $apiKey
    [string] $localModelPath
    [string] $modelIdentifier
    [string] $deploymentName
    [bool] $plainTextApiKey
}

class ModelResourceSettings {
    [ModelResource[]] $list
}

function GetDefaultSettingsLocation {
    "~/.chatgps/settings.json"
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

    if ( $targetPath -and ( test-path $targetPath ) ) {
        $settingsJson = Get-Content $targetPath | out-string

        $typedSettings = SettingsJsonToStrongTypedSettings $settingsJson $targetPath

        # Need untyped settings here because we want unspecified values to
        # show up as null -- distinction is crucial for integer and boolean
        # types for instance.
        $untypedSettings = SettingsJsonToUntypedSettings $settingsJson

        $global:myuntyped = $untypedsettings

        $sessions = GetSessionSettingsFromSettings $untypedSettings

        $currentProfile = GetConfiguredProfileFromSettings $typedSettings

        $currentSession = if ( $currentProfile -and $sessions ) {
            $targetSession = $sessions | where name -eq $currentProfile.sessionName

            if ( $currentProfile.sessionName ) {
                if ( $targetSession ) {
                    $targetSession
                } else {
                    write-warning "Unable to set the current session to the specified session '$($currentProfile.sessionName)' because no such setting could be found."
                }
            }
        }

        if ( $currentSession ) {
            SetCurrentSession $currentSession
        }

        $script:LastUsedSettingsPath = $targetPath
        $script:LastSettingsJson = $settingsJson

    } else {
        write-verbose "Settings already initialized = $isInitialized; env var CHATGPS_SKIP_SETTINGS_ON_LOAD = $($env:CHATGPS_SKIP_SETTINGS_ON_LOAD)"
        write-verbose "Configured settings path not found, settings initialization will be skipped."
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

function GetSessionSettingsFromSettings($settings) {
    $defaultSessionValues = $null

    $sessionList = if ( $settings.sessions ) {
        $defaultSessionValues = $settings.sessions.defaults
        $settings.sessions.list
    }

    $models = GetModelResourcesFromSettings $settings
    $global:mymod = $models
    $global:myset = $settings

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
        $model = $models | where name -eq $sourceSetting.modelName

        if ( $model ) {
            'modelIdentifier', 'provider', 'apiEndpoint', 'localModelPath', 'deploymentName' | foreach {
                $value = if ( $model | get-member $_ ) {
                    $model.$_ -ne '' ? $model.$_ : $null
                }

                if ( $null -ne $value ) {
                    $sessionParameters.Add($_, $value)
                }
            }
        } else {
            $isValidSetting = $false
        }
    }

    if ( $isValidSetting ) {
        'apiKey', 'tokenLimit' | foreach {
            $value = $sourceSetting.$_ -ne '' ? $sourceSetting.$_ : $null

            if ( $null -ne $value ) {
                $sessionParameters.Add($_, $value)
            }
        }

        if ( $sessionParameters.ContainsKey('apiKey') ) {
            $sessionParameters.Add('plainTextApiKey', [System.Management.Automation.SwitchParameter]::new($sourceSetting.plainTextApiKey))
        }

        try {
            Connect-ChatSession @sessionParameters -NoSetCurrent -NoConnect -PassThru -Force
        } catch {
            write-warning "Skipping incorrectly specified session setting '$($sourceSetting.Name)'. The following error was encountered: $($_.exception.message)"
        }
    } else {
        write-warning "Skipping session setting '$($sourceSetting.Name)' because it was incorrectly specified"
    }
}

function GetConfiguredProfileFromSettings([RootSettings] $settings) {
    if ( $settings ) {
        if ( ( $settings | get-member defaultProfile ) -and $settings.defaultProfile -and $settings.profiles -and $settings.profiles.list ) {
            $settings.profiles.list | where name -eq $settings.defaultProfile
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
