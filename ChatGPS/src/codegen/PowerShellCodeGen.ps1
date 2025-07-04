#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

& {
    $PowerShellInstructions = @"
You will generate the code in the form of a Powershell Script Block, starting with a param block with parameters inferred from the user's description of the desired functionality. This means your response shoudl start with the keyword param.
"@

    $responseCorrectionBlock = {
        param($responseText)
        $responseText.TrimStart('{').TrimEnd('}')
    }

    $responseValidationBlock = {
        param($responseText)
        [ScriptBlock]::Create($responseText) | out-null
    }

    $responseExecutableBlock = {
        param($responseText)
        [ScriptBlock]::Create($responseText)
    }

    AddLanguageGenerationInfo PowerShell $PowerShellInstructions $responseCorrectionBlock $responseValidationBlock $responseExecutableBlock

}
