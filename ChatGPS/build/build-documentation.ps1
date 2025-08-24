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
    [string] $ModuleName,

    [parameter(parametersetname='generate')]
    [string] $DocsParentDirectory = $null,

    [parameter(parametersetname='generate')]
    [switch] $GeneratePublishableDocs,

    [parameter(parametersetname='cleanonly')]
    [switch] $CleanOnly,

    [switch] $PassThru
)

. ("$psscriptroot/common-build-functions.ps1")

write-verbose "Starting documentation generation for module '$ModuleName'..."

$productionParent = join-path $psscriptroot ..

$rootDir = if ( $DocsParentDirectory ) {
    $DocsParentDirectory
} else {
    $productionParent
}

$parentPath = (Get-Item $rootDir).FullName

$productionDocsDir = 'docs'
$testDocsDir = 'testdocs'

$docsDir = if ( $GeneratePublishableDocs.IsPresent ) {
    $productionDocsDir
} else {
    $testDocsDir
}

$productionDocsPath = join-path $parentPath $productionDocsDir
$testDocsPath = join-path $parentPath $testDocsDir

$targetDocsDir = if ( $GeneratePublishableDocs.IsPresent ) {
    $productionDocsPath
} else {
    $testDocsPath
}

$commandRelativeDirectory = 'commands'

$commandHelpPath = join-path $parentPath $docsDir $commandRelativeDirectory

write-verbose "Command docs will be placed under the path '$commandHelpPath'"

if ( test-path $commandHelpPath ) {
    write-verbose "Deleting directory '$commandHelpPath'"
    remove-item -r -force $commandHelpPath
}

$generatedFiles = if ( ! $CleanOnly ) {
    write-verbose "Generating markdown files"

    New-Directory $commandHelpPath | out-null

    # Need to copy static files to the test directory
    if ( ! $GeneratepublishableDocs.IsPresent ) {
        get-childitem $productionDocsPath *.md |
          foreach {
              copy-item $_ $testDocsPath
          }
    }

    Get-Module $ModuleName |
      Select-Object -ExpandProperty ExportedFunctions |
      Select-Object -ExpandProperty Values |
      Select-Object -ExpandProperty Name |
      foreach {
          New-MarkdownHelp -command $_ -OutputFolder $commandHelpPath
      }

    & $psscriptroot/Get-CommandReferenceContent.ps1 -ModuleName $ModuleName -CommandHelpRelativeDirectory $commandRelativeDirectory | Out-File $targetDocsDir/CommandReference.md

    write-verbose "Finished generating markdown files."
} else {
    write-verbose "Skipping documentation generation because CleanOnly was specified"
}

if ( $PassThru.IsPresent -and $generatedFiles ) {
    $generatedFiles
}


