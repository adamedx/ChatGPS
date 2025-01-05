#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

[cmdletbinding(PositionalBinding=$false)]
param(
    [parameter(mandatory=$true)]
    [string] $TestTargetModuleDirectory,

    [parameter(mandatory=$true)]
    [string] $ToolsRootPath,

    [parameter(mandatory=$true)]
    [string] $ToolsModuleName,

    [parameter(mandatory=$true)]
    [string] $ToolsModuleVersion
)

. ("$psscriptroot/common-build-functions.ps1")

Enable-ModuleTools -ToolsRootPath $ToolsRootPath

$global:__ChatGPSSkipNative = $true # This updates files in the module directory, we don't want to do this.

$testToolManifestPath = & "$psscriptroot/Install-TestFx.ps1" -ToolsRootPath $ToolsRootPath -ModuleName $ToolsModuleName -Version $ToolsModuleVersion
import-module -force $testtoolManifestPath

$targetManifestPath = Find-ModuleManifestPath -ModuleDirectory $TestTargetModuleDirectory -Recurse
import-module -force $targetManifestPath

