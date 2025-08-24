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

#
set-strictmode -version 2

function New-Directory {
    param(
        [Parameter(mandatory=$true)]
        $Name,
        $Path,
        [switch] $Force
    )
    $fullPath = if ( $Path ) {
        join-path $Path $Name
    } else {
        $Name
    }
    $forceArgument = @{
        Force=$Force
    }

    new-item -ItemType Directory $fullPath @forceArgument
}

function Get-SourceRootDirectory {
    (get-item (split-path -parent $psscriptroot)).fullname
}

function Get-DevRepositoryName( [parameter(mandatory=$true)] [string] $ModuleName ) {
    "__$($ModuleName)__localdev"
}

function Get-DevRepositoryDirectory {
    $sourceRootDirectory = Get-SourceRootDirectory
    join-path $sourceRootDirectory '.psrepo'
}

function Unregister-DevRepository([parameter(mandatory=$true)] $ModuleName) {
    $existingRepository = get-psrepository (Get-DevRepositoryName $ModuleName) -erroraction silentlycontinue

    if ( $existingRepository ) {
        $existingRepository | unregister-psrepository | out-null
    }
}

function Configure-DevRepository([parameter(mandatory=$true)] [string] $ModuleName) {

    $localPSRepositoryDirectory = Get-DevRepositoryDirectory
    $localPSRepositoryName = Get-DevRepositoryName $ModuleName

    if ( ! ( test-path $localPSRepositoryDirectory ) ) {
        New-Directory $localPSRepositoryDirectory | out-null
    }

    $existingRepository = get-psrepository $localPSRepositoryName -erroraction silentlycontinue

    if ( $existingRepository -ne $null ) {
        unregister-psrepository $localPSRepositoryName | out-null
    }

    register-psrepository $localPSRepositoryName $localPSRepositoryDirectory | out-null

    Get-PSRepository $localPSRepositoryName
}

function Clean-DevRepository([switch] $Unregister, [string] $ModuleName) {
    if ( $Unregister.IsPresent ) {
        if ( ! $ModuleName ) {
            throw 'Cannot unregister the dev repository without specifying the module'
        }

        Unregister-DevRepository $ModuleName
    }

    $repositoryDirectory = Get-DevRepositoryDirectory

    if ( test-path $repositoryDirectory ) {
        $repositoryDirectory | remove-item -r -force
    }
}

function Get-ModuleName([string] $ModuleManifestPath) {
    # Note that on case sensitive file systems such as Linux,
    # the manifest file name MUST match the casing of the module itself
    # to avoid subsequent errors installing or generating the module
    $ModuleManifestPath | select -expandproperty basename
}

function Find-ModuleManifestPath {
    param(
        [parameter(mandatory=$true)]
        [string] $ModuleDirectory,
        [string] $ModuleName,
        [switch] $Recurse,
        [switch] $IgnoreNotFound
    )

    $targetDirectory = if ( $ModuleName ) {
        join-path $ModuleDirectory $ModuleName
    } else {
        $ModuleDirectory
    }

    $manifestPath = Get-ChildItem $targetDirectory -Filter *.psd1 -Recurse:$Recurse.IsPresent -erroraction ignore |
      sort-object fullname |
      Select-object -first 1

    $manifestCount = ( $manifestPath | measure-object ).Count

    if ( $manifestCount -eq 0 -and ! $IgnoreNotFound.IsPresent ) {
        write-error "Unable to find exactly one .psd1 file at the path '$targetDirectory'" -erroraction Stop
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

    $normalizedPath = (Get-Item $ToolsRootPath).FullName

    if ( ! ( $env:PSModulePath -like "*$($normalizedPath)*" ) ) {
        set-item env:PSModulePath ("$normalizedPath;" + $env:PSModulePath)
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
