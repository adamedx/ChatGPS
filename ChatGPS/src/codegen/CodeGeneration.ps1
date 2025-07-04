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

function GetCodeGenInfo( [string] $language, [string] $customGenerationInstructions, [bool] $skipSelfAssessment ) {
    $languageInfo = GetLanguageGenerationInfo $language

    $languageInstructions = if ( $languageInfo ) {
        $languageInfo.GenerationInstructions
    }

    $functionPrologue = "Translate the natural language text {{`$natural_language_definition}} to $($language) programming language code that accomplishes the goal of {{`$natural_language_definition}}."

    $specializedInstructions = if ( $languageInstructions ) {
        $languageInstructions
    } else {
        $script:DefaultLanguageInstructions
    }

    $errorSentinel = $null

    $selfAssessmentInstructions = if ( ! $skipSelfAssessment ) {
        $errorSentinel = [Guid]::newGuid().ToString()
        @"
If code that solves the user's request cannot be generated, then you MUST add the following string to the end of your response: '$errorSentinel'
"@
    }

      $requirementsInstructions =
    @"
Your entire response must be a valid fragment of code in the language $($language), unless you cannot satisfy the request because it doesn't make sense or is not possible. You must not embed the code in markdown formatting. This means the response must not start with ``` or end with ```. You may include explanation of the code, but only as comments valid in the specified language. If you have the ability to search the internet for examples of code that satisfies the user's request, you may perform the search and incorporate ideas from the search results into the result that you obtain. If you cannot generate code that satisfies the user's request, then respond with a sentence that says that you cannot generate the code and why.
"@

    $codeGenerationFunctionDefinition = $functionPrologue + "`n" +
        ( $customGenerationInstructions ? $customGenerationInstructions + "`n" : "" ) +
        $specializedInstructions + "`n" +
        $requirementsInstructions +
        ( $selfAssessmentInstructions ? $selfAssessmentInstructions + "`n" : "" )

    [PSCustomObject] @{
        GenerationFunctionDefinition = $codeGenerationFunctionDefinition
        ResponseCorrectionBlock = $languageInfo ? $languageInfo.ResponseCorrectionBlock : $null
        ValidationBlock = $languageInfo ? $languageInfo.ValidationBlock : $null
        ExecutableBlock = $languageInfo ? $languageInfo.ExecutableBlock : $null
        ErrorSentinel = $errorSentinel
    }
}

function GetGeneralVerifierFunctionDefinition([string] $language, [string] $definitionParameterName, [string] $modelResponseParameterName) {
    @"
A user has asked for the following natural language text to be translated to the programming language $($language): {{`$$($definitionParameterName)}}. The user received the following generated code in answer to that request: {{`$$($modelResponseParameterName)}}. Give a response of either yes or no to the answer of whether the answer is a valid and accurate reply to the user's question. If the answer does not satisfy the user's question, then you should say no. If the user asked for something that is not possible, then you should also say no, since it is not possible to satisfy an impossible request. If the generated code answer contains comments that indicate that the code is incorrect or solves a problem different than the one asked by the user, you should say no. And if the answer is simply wrong, then you should say no. But if the code does seem to answer the user's original question correctly, you should say yes. The first line of your response should be the either the word 'yes' or 'no' depending on whether the generated code satisfied the user's question. You may then add additional lines of text after that first line to explain your reasoning on why the response is deemed incorrect."
"@
}

function GenerateCodeForLanguage([string] $language, [string] $naturalLanguageDefinition, $languageModelSession, [int] $maxAttempts = 1, [string] $customGenerationInstructions, [bool] $noCmdletBinding, [bool] $skipSelfAssessment, [bool] $skipModelErrorDetection, $verifierModelSession) {

    $codeGenerationInfo = GetCodeGenInfo $Language $customGenerationInstructions $skipSelfAssessment

    $codeText = $null

    $languageException = $null

    $modelAttempts = 0

    $generationFunction = New-ChatFunction $codeGenerationInfo.GenerationFunctionDefinition

    for ( $attempts = 0; $attempts -lt $maxAttempts; $attempts++ ) {

        write-debug "Generating code using language model session $($languageModelSession.Id)"

        $responseText = $generationFunction | Invoke-ChatFunction -Session $languageModelSession -Parameters $naturalLanguageDefinition

        $codeText = if ( $codeGenerationInfo.ResponseCorrectionBlock ) {
            $codeGenerationInfo.ResponseCorrectionBlock.InvokeReturnAsIs($responseText)
        } else {
            $responseText
        }

        if ( $codeText ) {
            $errorSentinel = $codeGenerationInfo.ErrorSentinel

            if ( $errorSentinel -and $codeText.Contains($errorSentinel) ) {
                write-debug "Received a response from the model indicating that it is aware of a deficiency in the code that it generated."

                $languageException = [ArgumentException]::new("The language model processed the request generated the specified code but was unable to identify a solution in the target language. Consider refining the wording of the request and confirm that a solution exists. Additional parameters to increase the number of language model attempts may improve the chances of successful generation. Inspect the resulting output from the model for possible details on the reason why the request could not be fulilled:`n`n$($codeText)")
            }

            if ( $codeGenerationInfo.ValidationBlock ) {
                try {
                    $codeGenerationInfo.ValidationBlock.InvokeReturnAsIs($codeText)
                } catch {
                    $languageException = $_
                }
            }

            if ( ! $languageException -and ! $skipModelErrorDetection ) {
                $generalVerifierDefinition = GetGeneralVerifierFunctionDefinition $language userDefinition modelResponse

                $verifierFunction = new-chatfunction $generalVerifierDefinition

                $targetVerifierSession = if ( $verifierModelSession ) {
                    $verifierModelSession
                } else {
                    $languageModelSession
                }

                write-debug "Verifying the model's response using language model session $($targetVerifierSession.Id)"

                $verificationResponse = $verifierFunction | Invoke-ChatFunction -Session $targetVerifierSession -parameters @{
                    userDefinition=$naturalLanguageDefinition
                    modelResponse = $codeText
                }

                $explanation = if ( $verificationResponse ) {
                    $lines = $verificationResponse -split "`n"

                    $validResponse = $null -ne $lines ? ($lines[0]).Trim() : 'no-response-from-model'

                    if ( $validResponse -ne 'yes' ) {
                        if ($validResponse -ne 'no' ) {
                            write-warning "Code generation verification by the model returned an ambigous answer of '$validResponse', expecting either 'yes' or 'no'. The generated code may not be valid."
                        }
                        $skippedFirst = $false
                        $additionalInformation = $lines | foreach {
                            if ( $skippedFirst ) {
                                $_
                            }
                            $skippedFirst = $true
                        }

                        @"
The model generated the specified code, but inspection of its result indicates that code indicates that the result does not satisfactorily conform to the specification. The more details, including the generated code, follow:

Explanation: $additionalInformation

Generated code:
$codeText
"@
                    }
                }

                if ( $explanation ) {
                    write-debug $explanation
                    $languageException = [Modulus.ChatGPS.Models.AIServiceException]::new($explanation)
                }
            }
        }

        $modelAttempts = $attempts + 1

        if ( ! $languageException ) {
            break
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
