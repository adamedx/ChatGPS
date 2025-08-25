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
    [parameter(parametersetname='generate', mandatory=$true)]
    [string] $ModulePath,

    [parameter(parametersetname='generate')]
    [string] $DocsParentDirectory = $null,

    [switch] $Production
)

. ("$psscriptroot/common-build-functions.ps1")

if ( ! ( & $psscriptroot/Is-DocBuildDisabled.ps1 ) ) {
    write-verbose "Starting documentation generation for module '$ModulePath'..."

    $moduleName = split-path -leafbase $ModulePath

    & $psscriptroot/Initialize-Tools.ps1 -TestTargetModuleDirectory $modulePath -ToolsRootPath "$psscriptroot/../tools" -ToolsModuleName PlatyPS -ToolsModuleVersion 0.14.2

    & $psscriptroot/build-documentation -modulename $moduleName -GeneratePublishableDocs:($Production.IsPresent) -DocsParentDirectory $DocsParentDirectory
} else {
    write-verbose "Skipping documentation publishing because doc builds are disabled."
}

