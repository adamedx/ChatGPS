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

        [string] $SettingsFilePath = $null,

        [switch] $NoCreateProfile,

        [switch] $NoSetDefaultProfile,

        [switch] $DefaultSession,

        [switch] $NewFile,

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

        $settingsExist = $false

        $settings = if ( ! $NewFile.IsPresent ) {
            if ( test-path $targetPath ) {
                $settingsExist = $true
                $content = Get-Content $targetPath -raw

                SettingsJsonToStrongTypedSettings $content $targetPath
            } elseif ( $SettingsFilePath ) {
                write-error "The specified settings file at '$SettingsFilePath' does not exist. Specify a valid path and then retry the operation."
            }
        }

        if ( ! $settings ) {
            $settings = New-ChatSettings -PassThru -NoSession -NoWrite -NoProfile
        }

        $sessions = @()

        $models = @()

        $modelsbyName = @{}
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

        $settingInfo = GetSessionSettingsInfo $session

        $sessionInfo = $settingInfo.SourceSettings

        $sessionSetting = $sessionInfo.Session

        $sessionIndex = GetSessionSettingIndex $settings $session.Name

        if ( $SaveAs ) {
            if ( ( GetSessionSettingIndex $settings $SaveAs ) -ne -1 ) {
                throw [ArgumentException]::new("Specified value '$SaveAs' for the SaveAs parameter is invalid because there is an existing session setting with that name.")
            }
        }

        $modelIndex = if ( $sessionIndex -ge 0 ) {
            GetModelSettingIndex $settings $sessionSetting.modelName
        } else {
            -1
        }

        if ( ! $modelsByName.ContainsKey($sessionSetting.modelName) ) {
            $modelsByName.Add($sessionSetting.modelName, $modelIndex)

            if ( $modelIndex -eq -1 ) {
                $models += [PSCustomObject] @{
                    Location = -1
                    Setting = $sessionInfo.Model
                }
            }
        }

        if ( $SaveAs ) {
            $sessionIndex = -1
        }

        $sessions += [PSCustomObject] @{
            Location = $sessionIndex
            Setting = $sessionSetting
        }
    }

    end {
        if ( $sessions ) {
            foreach ( $model in $models ) {
                if ( $model.setting ) {
                    UpdateModelSetting $settings $model.Location $model.setting
                }
            }

            foreach ( $session in $sessions ) {
                if ( $SaveAs ) {
                    $session.Setting.Name = $SaveAs
                }
                UpdateSessionSetting $settings $session.Location $session.Setting $ProfileName $NoCreateProfile.IsPresent ( ! $settingsExist -and ! $NoSetDefaultProfile.IsPresent ) $DefaultSession.IsPresent
            }

            WriteSettings $settings $targetPath $NoWrite.IsPresent
        }
    }
}

RegisterSessionCompleter Save-ChatSessionSetting Name
RegisterSessionCompleter Save-ChatSessionSetting Id

