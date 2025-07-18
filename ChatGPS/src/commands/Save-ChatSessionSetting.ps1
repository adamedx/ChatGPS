#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

<#
.SYNOPSIS
Saves the current configuration of a chat session to the settings configuration file.

.DESCRIPTION
The Save-ChatSessionSetting command saves the configuration values of a given session to the settings configuration file; the saved state will represent the values returned by the Get-ChatSession command for that session. By saving this information to the file, the session will be available as soon as the ChatGPS module is imported into any PowerShell session, thus preserving the session for us across PowerShell sessions and operating system reboots. The Save-ChatSessionSetting command offers a convenient alternative to manually editing the configuration file as it can be used with no knowledge of the structure and format of the configuration file.

For more details about settings configuration see the documentation for the New-ChatSettings command.

By default, if there is no settings configuration file, Save-ChatSessionSetting will create a new settings file before saving the session information in the file so that the user does not need to remember to invoke the New-ChatSessionSettings command to explicitly create the file.

All information required for the session to be functional when starting a new PowerShell session is saved to the file. On the Windows operating system platform, this includes sensitive data including API keys; such parameters are encrypted when they are written to the file using the Get-ChatEncryptedUnicodeKeyCredential. See the documentation for that command and New-ChatSettingsInfo for details on the conditions in which such data stored in the file can be decrypted. On platforms other than Windows, these API key settings are not saved.

.PARAMETER Name
The name of the chat session to save; this is the same name that shows for the session when Get-ChatSession is used. If the session does not have a name, or if the session's identifier is already known, the Id parameter can be used instead of the name to choose the session to save.

.PARAMETER Id
The session id of the session to save. Unlike the use of the Name parameter, all sessions have an Id property, so this can always be used to identify a session. The value can be read from the pipeline, allowing multiple sessions to be piped to the command in order to save those sessions.

.PARAMETER Current
Specify this parameter to choose to save the current session; this makes it easy to save the current session without needing to identify the name or Id of the session.

.PARAMETER SaveAs
Specify a new session name to SaveAs to save the session to a new session setting. The saved setting will have a name property that is the same as the value of this parameter. This essentially "copies" the session being saved to a new session setting. It also has the side effect of immediately creating a new chat session as if Connect-ChatSession had been executed for the setting; a session with the name specified to the SaveAs parameter will be displayed if the Get-ChatSession command is invoked after SaveAs is used to save a setting.

.PARAMETER ProfileName
Specify ProfileName to set the default session of the specified profile. By default, the session information is saved but no profile information is changed unless there is no profile in the configuration file, in which case that default profile is created and set to use the session being saved as its default session.

.PARAMETER SettingsFilePath
Specify SettingsFilePath to write the settings information to a file system path other than the default settings configuration file at ~/.chatgps/settings.json.

.PARAMETER NoCreateProfile
Specify NoCreateProfile to avoid creating a profile. By default, if there is no profile in the settings file, a profile will be created and the saved session will be set as the default session for the profile.

.PARAMETER NoSetDefaultProfile
By default, if there is no default profile, the new profile is created unless the NoCreateProfile parameter is specified. Use the NoSetDefaultProfile parameter to ensure that the default profile is not configured with the session being saved under any circumstances.

.PARAMETER NoWrite
Specify NoWrite to avoid writing a file; instead, the deserialized form of the settings will be returned. This is useful if you intend to programmatically manage the settings or use a store other than the file system such as a cloud storage service, or if you want to inspect the changes that would be made by the command.

.PARAMETER Force
By default, if the SettingsFilePath parameter is specified and the file it references already exists, the command will fail in order to avoid overwriting data in an existing file. Specify Force to override this safety feature and write the data to the file.

.OUTPUTS
By default, the command does not return output. However if the NoWrite parameter is specified a deserialized object corresponding to the saved session information; this object can be serialized as JSON and inserted in to the settings file through manual editing or automation.

.EXAMPLE
Save-ChatSessionSetting -Current

This saves the current session to the configuration file.

.EXAMPLE
Save-ChatSessionSetting azure-gpt4

This example shows how to save a chat session by specifying the session's name.

.EXAMPLE
Save-ChatSessionSetting -Current -SaveAs azure-backup

In this example the current session is copied to another session configuration named "azure-backup".

.EXAMPLE
Get-ChatSession | Where-Object Name -like *azure* | Save-ChatSessionSetting

In this example, all sessions with the string 'azure' in the name are enumerated and then piped to Save-ChatSessionSetting to save all such sessions. The Id parameter of Save-ChatSessionSetting is used to pass the sessions to the pipeline.

.LINK
Get-ChatSession
New-ChatSessionSettings
Get-ChatSettingsInfo
Update-ChatSettings
#>
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

        $sessionPlugins = $session | Get-ChatPlugin

        $sessionCustomPluginSettings = if ( $sessionPlugins ) {
            if ( $customPluginSettings ) {
                $customPluginSettings |
                  where-object Name -in $sessionPlugins.Name
            }
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

