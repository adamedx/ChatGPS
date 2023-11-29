#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
set-strictmode -version 2

function Find-ModuleManifestPath {
    param(
        [parameter(mandatory=$true)]
        [string] $ModuleDirectory,
        [switch] $Recurse,
        [switch] $IgnoreNotFound
    )

    $manifestPath = Get-ChildItem $ModuleDirectory -Filter *.psd1 -Recurse:$Recurse.IsPresent -erroraction ignore
    $manifestCount = ( $manifestPath | measure-object ).Count

    if ( ( $manifestCount -eq 0 -and ! $IgnoreNotFound.IsPresent ) -or
         ( $manifestCount -gt 1 ) ) {
        write-error "Unable to find exactly one .psd1 file at the path '$ModuleDirectory'" -erroraction Stop
    }

    if ( $manifestPath ) {
        $manifestPath.FullName
    }
}

function Enable-ModuleTools {
    param(
        [parameter(mandatory=$true)]
        [string] $ToolsRootPath
    )

    if ( ! ( $env:PSModulePath -like "*$($ToolsRootPath)*" ) ) {
        set-item env:PSModulePath ("$ToolsRootPath;" + $env:PSModulePath)
    }
}

function Find-InstalledModuleToolManifestPath {
    param(
        [parameter(mandatory=$true)]
        [string] $ToolsRootPath,
        [parameter(mandatory=$true)]
        [string] $ModuleName,
        [parameter(mandatory=$true)]
        [string] $Version
    )

    $moduleRoot = join-path $ToolsRootPath $ModuleName $Version

    Find-ModuleManifestPath $moduleRoot -IgnoreNotFound -Recurse
}
