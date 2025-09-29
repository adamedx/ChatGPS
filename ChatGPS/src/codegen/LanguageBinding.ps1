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

$languageRunBlocks = @{
    PowerShell = $null
    Python = { param($code) "@'`n$($code)`n'@ | python" }
    Javascript = { param($code) "@'`n$($code)`n'@ | node -" }
}

function GetBoundCode($code, [string] $language = $null, [scriptblock] $runBlock = $null, [bool] $noScriptBlock = $false, [bool] $noBinding = $false) {

    $normalizedCode = if ( ! $noScriptBlock ) {
        $code
    } else {
        $code.ToString()
    }

    $languageTransformer = if ( $runBlock ) {
        $runBlock
    } else {
        $languageRunBlocks[$language]
    }

    $transformedCode = if ( $languageTransformer ) {
        $codeText = . $languageTransformer $normalizedCode
        [ScriptBlock]::Create($codeText)
    }

    if ( $transformedCode -and ! $noBinding ) {
        if ( ! $noScriptBlock ) {
            $transformedCode
        } else {
            $transformedCode.ToString()
        }
    } else {
        $code
    }
}

function RegisterLanguageCompleter([string] $command, [string] $parameterName) {

    $completer = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $languageRunBlocks.Keys | sort-object | where-object { $_.StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
    }

    Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock $completer
}
