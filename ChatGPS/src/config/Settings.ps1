#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptions.IncludeFields = $true

$LastUsedSettingsPath = $null
$LastSettingsJson = $null


# These class definitions represent the deserialized structure of the
# configuration file. Using PowerShell classes here to generate a native
# .Net type allows us to use a type-aware serializer like System.Text.Json
# for reliable and safe consumption of the settings file.

class RootSettings {
    [string]$defaultProfile
    [ProfileSettings]$profiles
    [SessionSettings]$sessions
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
    [string]$provider
    [Uri] $apiEndpoint
    [string] $apiKey
    [string] $localModelPath
    [string] $modelIdentifier
    [string] $deploymentName
    [int] $tokenLimit
    [bool] $signinInteractionAllowed
}


class SessionSettings {
    [ModelChatSession[]]$list
    [ModelChatSession]$defaults
}

function GetDefaultSettingsLocation {
    "~/.chatgps/settings.json"
}

function InitializeCurrentSettings([string] $settingsPath = $null) {
    $targetPath = if ( $settingsPath ) {
        $settingsPath
    } else {
        GetDefaultSettingsLocation
    }

    write-verbose "Resulting settings configuration path is '$settingsPath'"

    if ( test-path $targetPath ) {
        $settingsJson = Get-Content $targetPath | out-string

        $typedSettings = SettingsJsonToStrongTypedSettings $settingsJson

        # Need untyped settings here because we want unspecified values to
        # show up as null -- distinction is crucial for integer and boolean
        # types for instance.
        $untypedSettings = SettingsJsonToUntypedSettings $settingsJson

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
        write-verbose "Configured settings path not found, settings initialization will be skipped"
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

function SettingsJsonToStrongTypedSettings([string] $settingsJson) {
    [System.Text.Json.JsonSerializer]::Deserialize[RootSettings]($settingsJson, $jsonOptions)
}

function GetSessionSettingsFromSettings($settings) {
    $defaultSessionValues = $null

    $sessionList = if ( $settings.sessions ) {
        $defaultSessionValues = $settings.sessions.defaults
        $settings.sessions.list
    }

    foreach ( $sessionSetting in $sessionList ) {
        SessionSettingToSession $sessionSetting $defaultSessionValues
    }
}

function SessionSettingToSession($sessionSetting, $defaultValues) {
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
        Provider = $sourceSetting.provider
        ModelIdentifier = $sourceSetting.modelIdentifier
        AllowInteractiveSignin = [System.Management.Automation.SwitchParameter]::new($sourceSetting.signinInteractionAllowed)
    }

    $isValidSetting = if ( $null -eq $sessionSetting.name ) {
        write-warning "Skipping a session setting from the settings configuration because it is missing the required 'name' property."
        $false
    } else {
        $true
    }

    if ( $isValidSetting ) {
        'apiKey', 'apiEndpoint', 'localModelPath', 'deploymentName', 'tokenLimit' | foreach {
            $value = $sourceSetting.$_ -ne '' ? $sourceSetting.$_ : $null

            if ( $null -ne $value ) {
                $sessionParameters.Add($_, $value)
            }
        }

        try {
            Connect-ChatSession @sessionParameters -NoSetCurrent -NoConnect -PassThru -Force -NoProxy
        } catch {
            write-warning "Skipping incorrectly specified session setting '$($sourceSetting.Name)'. The following error was encountered: $($_.exception.message)"
        }
    }
}

function GetConfiguredProfileFromSettings([RootSettings] $settings) {
    if ( $settings.defaultProfile -and $settings.profiles -and $settings.profiles.list ) {
        $settings.profiles.list | where name -eq $settings.defaultProfile
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
