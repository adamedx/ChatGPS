#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Save-ChatSessionSetting {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, parametersetname='name', mandatory=$true)]
        [string] $Name = $null,

        [parameter(parametersetname='id', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='current', mandatory=$true)]
        [switch] $Current,

        [parameter(parametersetname='name')]
        [parameter(position=0, parametersetname='current')]
        [string] $SaveAs,

        [string] $ProfileName = $null,

        [Alias('Path')]
        [string] $SettingsFilePath = $null,

        [switch] $NoCreateProfile,

        [switch] $NoSetDefaultProfile,

        [switch] $DefaultSession,

        [switch] $NoNewFile,

        [switch] $NoWrite,

        [switch] $Force
    )

    begin {
        $targetPath = if ( $SettingsFilePath ) {
            if ( ( test-path $SettingsFilePath ) -and ! $Force.IsPresent ) {
                write-error "The specified settings file at '$SettingsFilePath' already exists; use the Force option to force this command to overwrite the existing settings"
            } else {
                $SettingsFilePath
            }
        } else {
            GetDefaultSettingsLocation
        }

        $currentSession = if ( $Current.IsPresent ) {
            Get-ChatSession -Current
        }

        # Load the latest settings from the configuration file (and if it doesn't exist, create "empty" settings).
        # Each session from the pipeline and its associated model information will be added to those settings
        # before all settings data (including non-session information like profiles) is written to the file
        # system (or pipeline output depending on command options). Note that if there is no existing settings file,
        # in addition to the session being added to the settings, a profile will be included and even configured
        # to use the session currently in the pipeline as the current session, modulo parameter overrides.

        $settingsExist = $false

        $settings = if ( test-path $targetPath ) {
            $settingsExist = $true
            $content = Get-Content $targetPath -raw

            SettingsJsonToStrongTypedSettings $content $targetPath
        } elseif ( $NoNewFile.IsPresent -and $SettingsFilePath ) {
            write-error "The specified settings file at '$SettingsFilePath' does not exist. Specify a valid path and then retry the operation."
        }

        if ( ! $settings ) {
            $settings = New-ChatSettings -PassThru -NoSession -NoWrite -NoProfile
        }

        $customPluginSettings = GetCustomPluginSettings $settings (Get-ChatPlugin -ListAvailable)

        $sessions = @()

        $models = @()

        $modelsbyName = @{}

        $customPlugins = @()

        $customPluginsByName = @{}
    }

    process {
        $session = if ( $Current.IsPresent ) {
            if ( $currentSession ) {
                $currentSession
            } else {
                return
            }
        } elseif ( $Id ) {
            Get-ChatSession -Id $Id
        } else {
            Get-ChatSession $Name
        }

        if ( ! $session ) {
            throw [ArgumentException]::new("Unable to find the session named '$Name'")
        }

        $sessionInfo = (GetSessionSettingsInfo $session).SourceSettings

        $sessionSetting = [ModelChatSession]::new($session, $sessionInfo.SessionSettings)

        # Check to see if the existing session by name exists in the settings by
        # looking up its existing index in the session collection. A value of anything
        # other tham -1 means it does exist indexed at that value, where -1 means
        # it does not exist.
        $sessionIndex = GetSessionSettingIndex $settings $session.Name

        if ( $SaveAs ) {
            if ( ( GetSessionSettingIndex $settings $SaveAs ) -ne -1 ) {
                throw [ArgumentException]::new("Specified value '$SaveAs' for the SaveAs parameter is invalid because there is an existing session setting with that name.")
            }
        }

        # Similarly look up models by their names in the models collection
        # to find an index into the collection if it exists.
        $modelIndex = if ( $sessionIndex -ge 0 ) {
            GetModelSettingIndex $settings $sessionSetting.modelName
        } else {
            -1
        }

        # Ensure that models with the same name are not added more than once
        # by checking to see if we already added it.
        if ( ! $modelsByName.ContainsKey($sessionSetting.modelName) ) {
            $modelsByName.Add($sessionSetting.modelName, $modelIndex)

            if ( $modelIndex -eq -1 ) {
                $models += [PSCustomObject] @{
                    Location = -1
                    Setting = $sessionInfo.ModelSettings
                }
            }
        }

        # In the SaveAs case, override any existing index so that the session
        # is treated as if it did not exist already so it can be saved as a
        # new session.
        if ( $SaveAs ) {
            $sessionIndex = -1
        }

        $sessionPlugins = Get-ChatPlugin -SessionId $session.id

        $sessionCustomPluginSettings = if ( $customPluginSettings ) {
            $customPluginSettings |
              where-object Name -in $sessionPlugins.Name
        }

        $sessionCustomPluginSettings | foreach {
            $customPluginIndex = GetCustomPluginSettingIndex $settings $_.Name

            if ( ! $customPluginsByName.ContainsKey($_.Name) ) {
                $customPluginsByName.Add($_.Name, $customPluginIndex)
            }

            if ( $customPluginIndex -eq -1 ) {
                $customPlugins += [PSCustomObject] @{
                    Location = -1
                    Setting = $_
                }
            }
        }

        $sessions += [PSCustomObject] @{
            Location = $sessionIndex
            Setting = $sessionSetting
            Plugins = $sessionPlugins
        }
    }

    end {
        $hasSettings = $false

        if ( $customPlugins ) {
            $hasSettings = $true
        }

        if ( $sessions ) {
            $hasSettings = $true

            # Now iterate through the models and settings that were sent to the pipeline,
            # and update their values in their respective settings collection based on the
            # location property. If that propery is -1, this will add the model or session
            # to the settings collection.

            foreach ( $model in $models ) {
                if ( $model.setting ) {
                    UpdateModelSetting $settings $model.Location $model.setting
                }
            }

            foreach ( $customPlugin in $customPlugins ) {
                UpdateCustomPluginSetting $settings $customPlugin.Location $customPlugin.Setting
            }

            foreach ( $session in $sessions ) {
                if ( $SaveAs ) {
                    $session.Setting.Name = $SaveAs
                }

                $pluginParameterData = @{}

                if ( $session.Plugins ) {
                    $pluginParameterTables = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PluginParameterValue]]]::new()

                    foreach ( $sessionPlugin in $session.Plugins ) {
                        $pluginParameterTables.Add($sessionPlugin.Name, $sessionPlugin.Parameters)
                    }

                    $session.Setting.Plugins = $pluginParameterTables
                }

                UpdateSessionSetting $settings $session.Location $session.Setting $ProfileName $NoCreateProfile.IsPresent ( ! $settingsExist -and ! $NoSetDefaultProfile.IsPresent ) $DefaultSession.IsPresent
            }

            # This is a new session setting, so create the session for it before we write it to the file.
            # This ensures that before we write to the file, we have a valid setting and won't save something
            # that will generate warnings when the settings are loaded.
            if ( $SaveAs ) {
                CreateSessionFromSettings $settings $SaveAs | out-null
            }
        }

        if ( $hasSettings ) {
            WriteSettings $settings $targetPath $NoWrite.IsPresent
        }
    }
}

RegisterSessionCompleter Save-ChatSessionSetting Name
RegisterSessionCompleter Save-ChatSessionSetting Id

