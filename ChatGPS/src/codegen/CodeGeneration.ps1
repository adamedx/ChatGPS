#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

$LanguageGenerationInfo = @{}

$DefaultLanguageInstructions = @"
Please use the standard conventions of this language when generating code.
"@

function AddLanguageGenerationInfo(
    [string] $language,
    [string] $generationInstructions,
    [scriptblock] $responseCorrectionBlock,
    [scriptblock] $validationBlock,
    [scriptblock] $executableBlock
) {
    $languageInfo = [PSCustomObject] @{
        GenerationInstructions = $generationInstructions
        ResponseCorrectionBlock = $responseCorrectionBlock
        ValidationBlock = $validationBlock
        ExecutableBlock = $executableBlock
    }

    $script:LanguageGenerationInfo.Add($language, $languageInfo)
}

function GetLanguageGenerationInfo([string] $language) {
    $script:LanguageGenerationInfo[$language]
}

function GetCodeGenInfo( [string] $language, [string] $customGenerationInstructions ) {
    $languageInfo = GetLanguageGenerationInfo $language

    $languageInstructions = if ( $languageInfo ) {
        $languageInfo.GenerationInstructions
    }

    $basePrompt = "Translate the natural language text {{`$natural_language_definition}} to $($language) programming language code that accomplishes the goal of {{`$natural_language_definition}}."

    $specializedPrompt = if ( $languageInstructions ) {
        $languageInstructions
    } else {
        $script:DefaultLanguageInstructions
    }

    $requirementsPrompt =
    @"
Your entire response must be a valid fragment of code in the language $($language), unless you cannot satisfy the request because it doesn't make sense or is not possible. You must not embed the code in markdown formatting. This means the response must not start with ``` or end with ```. You may include explanation of the code, but only as comments valid in the specified language. If you have the ability to search the internet for examples of code that satisfies the user's request, you may perform the search and incorporate ideas from the search results into the result that you obtain. If you cannot generate code that satisfies the user's request, then just respond with a sentence that says that you cannot generate the code and why.
"@

    $codeGenerationSystemPrompt = $basePrompt + "`n" +
        ($customGenerationInstructions ? $customGenerationInstructions + "`n" : "" ) +
        $specializedPrompt + "`n" +
        $requirementsPrompt

    [PSCustomObject] @{
        GenerationInstructions = $codeGenerationSystemPrompt
        ResponseCorrectionBlock = $languageInfo ? $languageInfo.ResponseCorrectionBlock : $null
        ValidationBlock = $languageInfo ? $languageInfo.ValidationBlock : $null
        ExecutableBlock = $languageInfo ? $languageInfo.ExecutableBlock : $null
    }
}

function GenerateCodeForLanguage([string] $language, [string] $naturalLanguageDefinition, $languageModelSession, [int] $maxAttempts = 1, [string] $customGenerationInstructions, [bool] $allowAgentAccess, [bool] $noCmdletBinding) {
    $codeGenerationInfo = GetCodeGenInfo $Language $customGenerationInstructions

    $codeText = $null

    $languageException = $null

    $modelAttempts = 0

    $translationFunction = New-ChatFunction $codeGenerationInfo.GenerationInstructions

    for ( $attempts = 0; $attempts -lt $maxAttempts; $attempts++ ) {
        $responseText = $translationFunction | Invoke-ChatFunction -Session $languageModelSession -Parameters @{natural_language_definition=$naturalLanguageDefinition}

        $codeText = if ( $codeGenerationInfo.ResponseCorrectionBlock ) {
            $codeGenerationInfo.ResponseCorrectionBlock.InvokeReturnAsIs($responseText)
        } else {
            $responseText
        }

        if ( $codeText -and $codeGenerationInfo.ValidationBlock ) {
            try {
                $codeGenerationInfo.ValidationBlock.InvokeReturnAsIs($codeText)
            } catch {
                $languageException = $_
            }
        }

        if ( ! $languageException ) {
            $modelAttempts = $attempts + 1
            break
        } else {
            continue
        }
    }

    $executableBlock = if ( $codeGenerationInfo.ExecutableBlock ) {
        $generatedExecutable = $codeGenerationInfo.ExecutableBlock.InvokeReturnAsIs($codeText)

        if ( $noCmdletBinding ) {
            $generatedExecutable
        } else {
            $generatedText = $generatedExecutable.ToString()
            if ( ! $generatedText.TrimStart().StartsWith('[cmdletbinding') ) {
                [ScriptBlock]::Create("[cmdletbinding()]`n$($generatedText)")
            } else {
                $generatedExecutable
            }
        }
    }

    [PSCustomObject] @{
        CodeText = $codeText
        ExecutableScriptBlock = $executableBlock
        GenerationException = $languageException
        ModelAttempts = $modelAttempts
    }
}
