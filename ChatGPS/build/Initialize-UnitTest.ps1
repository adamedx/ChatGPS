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
    [string] $TestTargetModuleDirectory,

    [parameter(mandatory=$true)]
    [string] $ToolsRootPath,

    [parameter(mandatory=$true)]
    [string[]] $ToolsModuleName,

    [parameter(mandatory=$true)]
    [string[]] $ToolsModuleVersion
)

. ("$psscriptroot/common-build-functions.ps1")

if ( ! ( test-path $ToolsRootPath ) ) {
    new-directory $ToolsRootPath | out-null
}

Enable-ModuleTools -ToolsRootPath $ToolsRootPath

$global:__ChatGPSSkipNative = $true # This updates files in the module directory, we don't want to do this.

set-item env:CHATGPS_SKIP_SETTINGS_ON_LOAD 'true'

$versionIndex = 0

foreach ( $module in $toolsModuleName ) {
    $version = $ToolsModuleVersion[$versionIndex++]

    if ( ! $version ) {
        throw [ArgumentException]::new("Missing version number for module '$module'")
    }

    $targetManifestPath = Find-ModuleManifestPath -ModuleDirectory $TestTargetModuleDirectory
    import-module -force $targetManifestPath
}

