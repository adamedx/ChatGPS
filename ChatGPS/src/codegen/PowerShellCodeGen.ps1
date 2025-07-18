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

function GenerateScriptBlockFromCodeText([string] $codeText) {
    try {
        [ScriptBlock]::Create($codeText)
    } catch {
        throw [FormatException]::new("Code generation failed with the error '$_'. The generated code was not valid code in this language. Ensure that the problem specified in the natural language description has any possible solution within this programming language, and if so, consider increasing the number of attempts the language model should use for difficult problems. See the following generated code: `n$($codeText)`n", $_.exception)
    }
}

& {
    $PowerShellInstructions = @"
You will generate the code in the form of a Powershell Script Block, starting with a param block with parameters inferred from the user's description of the desired functionality. This means your response shoudl start with the keyword param.
"@

    $responseCorrectionBlock = {
        param($responseText)
        if ( $responseText.Trim().StartsWith('{') ) {
            $responseText.TrimStart('{').TrimEnd('}')
        } else {
            $responseText
        }
    }

    $responseValidationBlock = {
        param($responseText)
        GenerateScriptBlockFromCodeText $responseText | out-null
    }

    $responseExecutableBlock = {
        param($responseText)
        GenerateScriptBlockFromCodeText $responseText
    }

    AddLanguageGenerationInfo PowerShell $PowerShellInstructions $responseCorrectionBlock $responseValidationBlock $responseExecutableBlock

}
