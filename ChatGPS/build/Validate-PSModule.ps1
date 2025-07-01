#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

[cmdletbinding(PositionalBinding=$false)]
param(
    [parameter(mandatory=$true)]
    [string] $ModuleDirectory
)
. ("$psscriptroot/common-build-functions.ps1")

$erroractionpreference = 'stop'

$moduleManifestPath = Find-ModuleManifestPath -ModuleDirectory $ModuleDirectory

Test-ModuleManifest $moduleManifestPath -erroraction stop | out-null

$global:__ChatGPSSkipNative = $true

try {
    set-item env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE ([Guid]::NewGuid().ToString())
    import-module $moduleManifestPath -force -erroraction stop | out-null
} finally {
    remove-item env:CHATGPS_DEFAULT_SETTINGS_PATH_OVERRIDE
}
