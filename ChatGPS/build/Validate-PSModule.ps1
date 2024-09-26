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

import-module $moduleManifestPath -force -erroraction stop | out-null
