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

