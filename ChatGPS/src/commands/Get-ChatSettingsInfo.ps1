#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Get-ChatSettingsInfo {
    [cmdletbinding(positionalbinding=$false)]
    param()

    [PSCustomObject] @{
        LastSettingsLocation = (GetLastSettingsPath)
        DefaultSettingsLocation = (GetDefaultSettingsLocation)
        Settings = (GetLastSettings)
    }
}
