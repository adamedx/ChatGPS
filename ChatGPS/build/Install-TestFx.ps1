#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

[cmdletbinding(PositionalBinding=$false)]
param(
    [parameter(mandatory=$true)]
    [string] $ToolsRootPath,
    [parameter(mandatory=$true)]
    [string] $ModuleName,
    [parameter(mandatory=$true)]
    [string] $Version

)
. ("$psscriptroot/common-build-functions.ps1")

$moduleManifestPath = Find-InstalledModuleToolManifestPath -ToolsRootPath $ToolsRootPath -ModuleName $ModuleName -Version $Version

if ( ! $moduleManifestPath ) {
    Save-Module $moduleName -Path $ToolsRootPath -RequiredVersion $Version -ErrorAction stop
    $moduleManifestPath = Find-InstalledModuleToolManifestPath -ToolsRootPath $ToolsRootPath -ModuleName $ModuleName -Version $Version -ErrorAction stop
}

if ( ! $moduleManifestPath ) {
    write-error "Unable to find test framework manifest for module '$ModuleName' version '$Version' into directory '$ToolsRootPath'" -erroraction stop
}

Test-ModuleManifest $moduleManifestPath -erroraction stop | out-null

$moduleManifestPath

