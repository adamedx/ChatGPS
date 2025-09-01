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

[cmdletbinding(supportsshouldprocess=$true, confirmimpact='High')]
param($ModuleDirectory, $RepositoryName = $null, $RepositoryKeyFile = $null)

. "$psscriptroot/common-build-functions.ps1"

$erroractionpreference = 'stop'

$moduleManifestPath = Find-ModuleManifestPath $ModuleDirectory

$module = Test-ModuleManifest $moduleManifestPath

$targetRepository = if ( $RepositoryName ) {
    Get-PSRepository $RepositoryName
} elseif ( $RepositoryKeyFile ) {
    Get-PSRepository 'psgallery'
} else {
    Clean-DevRepository $module.Name -Unregister
    Configure-DevRepository $module
}

if ( ! $targetRepository ) {
}

$targetRepositoryName = $targetRepository.Name
$moduleOutputPath = $targetRepository.SourceLocation
$moduleDirectory = split-path -Parent $moduleManifestPath

write-host "Publishing module at '$moduleDirectory' to PS module repository '$targetRepositoryName' at '$moduleOutputPath'..."

$repositoryKey = if ( $repositoryKeyFile -ne $null ) {
    Get-RepositoryKeyFromFile $repositoryKeyFile
}

if ( ! $repositoryKey -or $pscmdlet.shouldprocess($moduleManifestPath, "Publish to public repository '$targetRepositoryName'") ) {
    $keyArgument = if ( $repositoryKey ) {
        @{NugetApiKey=$repositoryKey}
    } else {
        @{}
    }

    publish-module -Path $moduleDirectory -Repository $targetRepositoryName @keyArgument | out-null

    Unregister-DevRepository $module.Name

    write-host "Module '$($module.name)' successfully published to repository $targetRepositoryName."
    write-host -foregroundcolor green "Publish module succeeded."
}
