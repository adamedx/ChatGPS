#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$jsonOptionsRead = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptionsRead.IncludeFields = $true
$jsonOptionsRead.IgnoreNullValues = $true

$jsonOptionsWrite = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptionsWrite.IncludeFields = $true
$jsonOptionsWrite.WriteIndented = $true

$jsonPSSerializerDepth = 10

$LastUsedSettingsPath = $null
$LastSettingsJson = $null
$LastSettings = $null

$SettingsInitialized = $false

# Trick to ensure that the attribute 'Microsoft.SemanticKernel.KernelFunctionAttribute' exists during module initialization
$aiDependencyPath = (get-item (join-path "$psscriptroot/../../lib" 'Microsoft.SemanticKernel.Abstractions.dll')).fullName
[System.Reflection.Assembly]::LoadFrom($aiDependencyPath) | out-null


# These class definitions represent the deserialized structure of the
# configuration file. Using PowerShell classes here to generate a native
# .Net type allows us to use a type-aware serializer like System.Text.Json
# for reliable and safe consumption of the settings file.

class RootSettings {
    RootSettings() {
        $this.sessions = [SessionSettings]::new()
        $this.models = [ModelResourceSettings]::new()
        $this.customPlugins = [CustomPluginResourceSettings]::new()
    }

    [string]$generatedDate
    [string]$generatedTool
    [string]$lastUpdatedDate
    [string]$lastUpdatedTool
    [string]$defaultProfile
    [ProfileSettings]$profiles
    [SessionSettings]$sessions
    [ModelResourceSettings]$models
    [CustomPluginResourceSettings]$customPlugins
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
        $this.allowAgentAccess = $null
        $this.historyContextLimit = -1
    }

    ModelChatSession([Modulus.ChatGPS.Models.ChatSession] $session, [ModelChatSession] $originalSettings) {
        foreach ( $member in ($originalSettings | get-member -membertype property).name ) {
            $this.$member = $originalSettings.$member
        }

        # Now initialize any mutable settings
        $this.allowAgentAccess = $session.AiOptions.AllowAgentAccess

        [ModelChatSession]::SetPlugins($this, $session.Plugins)
    }

    static [void] SetPlugins([ModelChatSession] $sessionSettings, [System.Collections.Generic.IEnumerable[Modulus.ChatGPS.Plugins.Plugin]] $plugins) {
        $sessionSettings = if ( $plugins ) {
            $sessionPlugins = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PluginParameterValue]]]::new()

            foreach ( $plugin in $plugins ) {
                $sessionPlugins.Add($plugin.Name, $plugin.Parameters)
            }

            $sessionSettings
        }
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
    [int] $tokenLimit = $null
    [string] $tokenStrategy
    [int] $historyContextLimit = $null
    [bool] $signinInteractionAllowed
    [bool] $plainTextApiKey
    [bool] $allowAgentAccess
    [System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PluginParameterValue]]] $plugins
    [string] $logDirectory
    [string] $logLevel
}


class SessionSettings {
    [System.Collections.Generic.List[ModelChatSession]]$list
    [ModelChatSession]$defaults
}

class ModelResource {
    ModelResource() {}
    ModelResource([Modulus.ChatGPS.Models.AiOptions] $options, [string] $name = $null) {
        get-member -property $this |
          select-object -expandproperty name |
          foreach {
            if ( $_ -ne 'name' ) {
                $this.$_ = $options.$_
            }
          }

        $this.name = $name
    }

    [bool] IsCompatible([Modulus.ChatGPS.Models.AiOptions] $options) {
        $isCompatible = $false

        get-member -property $this |
          select-object -expandproperty name |
          foreach {
            if ( $_ -ne 'name' ) {
                if ( $this.$_ -ne $options.$_ ) {
                    $isCompatible = $false
                    break
                }
            }
          }

        return $isCompatible
    }

    [string] $name = $null
    [string] $provider
    [Uri] $apiEndpoint
    [string] $localModelPath
    [string] $modelIdentifier
    [string] $serviceIdentifier
    [string] $deploymentName
}

class ModelResourceSettings {
    [System.Collections.Generic.List[ModelResource]] $list
}

class CustomPluginResource {
    [string] $Name
    [string] $Description
    [string] $PluginType
    [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]] $Functions
}

class CustomPluginResourceSettings {
    [System.Collections.Generic.List[CustomPluginResource]] $list
}

function GetDefaultSettingsLocation {
    if ( ! $env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE ) {
        "~/.chatgps/settings.json"
    } else {
        write-verbose "The default settings path has been overridden by the environment variable CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE. The resulting value is '$($env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE)'"
        $env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE
    }
}

function InitializeModuleSettings {
    try {
        InitializeCurrentSettings
    } catch {
        write-warning "Unable to initialize settings -- the module initialized successfully but settings from configuration file could not be applied, possibly due to corruption of the file. Use the Get-ChatSettingsInfo command to obtain the path to the configuration file to correct the error or delete the file if the configuration is not needed to prevent recurrence of this warning. The error was '$($_.exception.message)'."
    }
}

function InitializeCurrentSettings([string] $settingsPath = $null) {
    $isInitialized = $script:SettingsInitialized

    $script:SettingsInitialized = $true

    $targetPath = if ( $isInitialized -or ! ( $env:CHATGPS_SKIP_SETTINGS_ON_LOAD -eq 'true' ) ) {
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

        # Expect that null settings are skipped here, which avoids issues with
        # null integer and boolean values showing up as 0 and false respectively --
        # this is semantically problematic since null is an allowable value
        # for integers and booleans in serialized JSON.
        $sessions = CreateSessionFromSettings $typedSettings

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

function SettingsJsonToStrongTypedSettings([string] $settingsJson, [string] $settingsSource) {
    try {
        [System.Text.Json.JsonSerializer]::Deserialize[RootSettings]($settingsJson, $jsonOptionsRead)
    } catch {
        write-warning "The settings at location '$settingsSource' are incorrectly formatted. The following error was encountered reading the data: $($_.Exception.Message)"
    }
}

function GetModelResourcesFromSettings($settings) {
    if ( $settings | get-member models ) {
        $settings.models.list
    }
}

function GetCustomPluginResourcesFromSettings($settings) {
    if ( ( $settings | get-member customPlugins ) -and $settings.customPlugins ) {
        if ( $settings.customPlugins | get-member list ) {
            $settings.customPlugins.list
        }
    }
}

function GetExplicitSessionSettingsFromSessionParameters($session, $sessionParameters, $pluginProviders) {
    $sessionSettings = [ModelChatSession]::new()

    if ( ! $sessionParameters ) {
        throw [ArgumentException]::new('The specified session does not contain configuration information')
    }

    $generatedName = "$([DateTimeOffset]::now.tostring('d'))-$($session.Id)"

    $sessionSettings.name = if ( $session.Name ) {
        $Session.Name
    } else {
        $generatedName
    }

    $modelSettings = GetExplicitModelSettingsFromSessionsByName $sessionSettings.modelName

    if ( ! $modelSettings -or ! $modelSettings.name ) {
        $targetModelName = !! $session.AiOptions.ModelIdentifier ? $session.AiOptions.ModelIdentifier : $session.AiOptions.DeploymentName

        if ( ! $targetModelName ) {
            $targetModelName = "$($session.AiOptions.Provider.ToString()) model"
        }

        if ( GetExplicitModelSettingsFromSessionsByName $targetModelName ) {
            $targetModelName = $session.AiOptions.Provider.ToString() + " - $targetModelName"
        }

        if ( GetExplicitModelSettingsFromSessionsByName $targetModelName ) {
            $targetModelName += " $generatedName"
        }

        $sessionSettings.modelName = $targetModelName
    }

    'apiKey', 'systemPromptId', 'customSystemPrompt', 'tokenLimit', 'tokenStrategy', 'historyContextLimit', 'logDirectory', 'logLevel' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
        $sessionSettings.$_ = $sessionParameters[$_]
    }

    'allowAgentAccess', 'noProxy', 'forceProxy', 'signinInteractionAllowed', 'plainTextApiKey' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
        $sessionSettings.$_ = $sessionParameters[$_].IsPresent
    }

    'sendblock', 'receiveBlock' |
      where { $sessionParameters.ContainsKey($_) } |
      foreach {
          $sessionSettings.$_ = $sessionParameters[$_].ToString()
      }

    $sessionPlugins = $null

    if ( $sessionParameters.ContainsKey('Plugins') ) {
        $sessionPlugins = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PluginParameterValue]]]::new()
        $pluginNames = $sessionParameters['Plugins']
        $pluginParameters = if ( $sessionParameters.ContainsKey('PluginParameters') ) {
            $sessionParameters['pluginParameters']
        } else {
            @{}
        }

        foreach ( $pluginName in $pluginNames ) {
            if ( $null -ne $pluginParameters -and $pluginParameters.ContainsKey($pluginName) ) {
                $parameterInfo = GetPluginParameterInfo $pluginName $pluginParameters[$pluginName]
                $sessionPlugins.Add($pluginName, $parameterInfo)
            }
        }
    }

    $sessionSettings.plugins = $sessionPlugins

    if ( ! $sessionSettings.apiKey -and $session.CustomContext['AiOptions'] ) {
        $sessionSettings.apiKey = $session.CustomContext['AiOptions'].ApiKey
    }

    if ( ! $modelSettings ) {
        $modelSettings = [ModelResource]::new()
        $modelSettings.Name = $sessionSettings.modelName
        $modelSettings.provider = $session.AiOptions.Provider
        $modelSettings.apiEndpoint = $session.AiOptions.ApiEndpoint
        $modelSettings.localModelPath = $session.AiOptions.LocalModelPath
        $modelSettings.modelIdentifier = $session.AiOptions.ModelIdentifier
        $modelSettings.deploymentName = $session.AiOptions.DeploymentName
        $modelSettings.serviceIdentifier = $session.AiOptions.serviceIdentifier
    }

    [PSCustomObject] @{
        SessionSettings = $sessionSettings
        ModelSettings = $modelSettings
    }
}

function GetCustomPluginSettings($settings, $pluginProviders) {
    $customPluginProviders = $pluginProviders | where { $_.IsCustom() }

    $customPluginSettings = if ( $customPluginProviders ) {
        foreach ( $provider in $customPluginProviders ) {
            if ( $provider -isnot [Modulus.ChatGPS.Plugins.PowerShellPluginProvider ] ) {
                write-warning "Skipping custom plugin setting '$($provider.Name)' of type '$($provider.GetType().FullName)' because it is not currently supported as a valid setting."
                continue
            }

            $customPluginSetting = [CustomPluginResource]::new()
            $customPluginSetting.Name = $provider.Name
            $customPluginSetting.Description = $provider.Description
            $customPluginSetting.PluginType = $provider.GetType().FullName
            $customPluginSetting.Functions = [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]]::new()

            $functions = $provider.GetScripts()

            if ( $functions ) {
                $customPluginSetting.Functions = $functions
            }

            $customPluginSetting
        }
    }

    $customPluginSettings
}

function CreateSessionFromSettings($settings, $sessionName = $null) {
    $defaultSessionValues = $null

    $sessionList = if ( $settings.sessions ) {
        $defaultSessionValues = $settings.sessions.defaults
        if ( $sessionName ) {
            $settings.sessions.list | where Name -eq $sessionName
        } else {
            $settings.sessions.list
        }
    }

    $models = GetModelResourcesFromSettings $settings

    # When this is specified, we're simply creating a session and
    # can assume everything outside of the function such as custom plugins
    # is already defined.
    if ( ! $sessionName ) {
        CreateCustomPluginsFromSettings $settings
    }

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

function CreateCustomPluginsFromSettings($settings) {
    $customPluginSettings = GetCustomPluginResourcesFromSettings $settings

    foreach ( $pluginSetting in $customPluginSettings ) {
        try {
            $functions = foreach ( $functionName in $pluginSetting.Functions.Keys ) {
                $function = $pluginSetting.Functions[$functionName]
                Add-ChatPluginFunction $functionName -ScriptBlock ([ScriptBlock]::Create($function.ScriptBlock)) -Description $function.Description -OutputType $function.OutputType -OutputDescription $function.OutputDescription
            }

            $functions |
              Register-ChatPlugin -Name $pluginSetting.Name -description $pluginSetting.Description | out-null
        } catch {
            write-warning "Failed to add custom plugin '$($pluginSetting.Name)'; the plugin will be skipped. The error was: $($_.exception.message)"
        }
    }
}

function SessionSettingToSession($sessionSetting, $defaultValues, $models) {
    $sourceSetting = [ModelChatSession]::new()

    $members = ($sourceSetting | Get-Member -MemberType Property).Name

    foreach ( $member in $members ) {
        if ( $sessionSetting | get-member $member ) {
            $sourceSetting.$member = $sessionSetting.$member
        }
    }

    $sessionParameters = @{
        Name = $sourceSetting.name
        AllowInteractiveSignin = [System.Management.Automation.SwitchParameter]::new($sourceSetting.signinInteractionAllowed)
        AllowAgentAccess = [System.Management.Automation.SwitchParameter]::new($sourceSetting.allowAgentAccess)
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
        $model = if ( $models ) {
            $models | where-object { $null -ne $_ } | where-object name -eq $sourceSetting.modelName
        }

        if ( $model ) {
            'serviceIdentifier', 'modelIdentifier', 'provider', 'apiEndpoint', 'localModelPath', 'deploymentName' | foreach {
                $value = if ( $model | get-member $_ ) {
                    # Yes, you must have empty string on the LHS because 0 -eq '' is true (???) but '' -eq 0 is false :(
                    '' -ne $model.$_ ? $model.$_ : $null
                }

                if ( $null -ne $value ) {
                    $sessionParameters.Add($_, $value)
                }
            }

            'forceProxy', 'noProxy' | foreach {
                if ( $sourceSetting | get-member $_ ) {
                    $sessionParameters.Add($_, [System.Management.Automation.SwitchParameter]::new($sourceSetting.$_))
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

        if ( $sourceSetting.plugins ) {
            $pluginTable = @{}

            foreach ( $pluginName in $sourceSetting.plugins.Keys ) {
                $parameters = @{}

                foreach ( $parameterName in $sourceSetting.plugins[$pluginName].Keys ) {
                    $parameters.Add($parameterName, $sourceSetting.plugins[$pluginName][$parameterName].GetValue())
                }

                $pluginTable.Add($pluginName, $parameters)
            }
            $sessionParameters.Add('PluginParameters', $pluginTable)
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
            if ( $settingCollection.list[$current].Name -eq $settingName ) {
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
    GetSettingIndex $settings.models $modelName
}

function GetCustomPluginSettingIndex([RootSettings] $settings, [string] $customPluginName) {
    GetSettingIndex $settings.customPlugins $customPluginName
}

function UpdateCustomPluginSetting([RootSettings] $settings, [int] $pluginIndex, [CustomPluginResource] $customPluginSetting) {
    if ( $null -eq $settings.customPlugins.list ) {
        $settings.customPlugins.list = [System.Collections.Generic.List[CustomPluginResource]]::new()
    }

    if ( $pluginIndex -ne -1 ) {
        $settings.customPlugins.list[$pluginIndex] = $customPluginSetting
    } else {
        $settings.customPlugins.list.Add($customPluginSetting)
    }
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
        $serialized = [System.Text.Json.JsonSerializer]::Serialize($settings, $jsonOptionsWrite)
        $serialized | set-content -encoding utf8 -path $settingsPath
    } else {
        $settings
    }
}
