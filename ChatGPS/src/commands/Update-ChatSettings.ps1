#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Update-ChatSettings {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)] [string] $SettingsFilePath = $null
    )
    InitializeCurrentSettings $SettingsFilePath
}
