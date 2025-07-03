#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Build-ChatCode {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [string] $Definition,

        [parameter(position=1, parametersetname='powershell')]
        [Alias('Function')]
        [string] $FunctionName,

        [string] $Language = 'PowerShell',

        [parameter(parametersetname='powershell')]
        [switch] $NoScriptBlock,

        [switch] $AllowAgentAccess,

        [int] $MaxRetries = 3,

        [string] $SessionName,

        [switch] $Force
    )

    set-strictmode -version 2

    $erroractionpreference = 'stop'

    if ( $MaxRetries -gt 50 ) {
        throw new [ArgumentException]::new("The specified MaxRetries value of $($MaxRetries) exceeds the maximum allowed value of 50 for this parameter")
    }

    $targetSession = if ( $SessionName ) {
        Get-ChatSession $SessionName
    } else {
        Get-ChatSession -Current
    }

    $isPowerShell = $Language -eq 'PowerShell'
    $expectScriptBlock = $isPowershell

    $basePrompt = "You are an assistant that translates natural language to $($Language) programming language code."

    $specializedPrompt = if ( $isPowerShell ) {
        @"
You will generate the code in the form of a Powershell Script Block, starting with a param block with parameters inferred from the user's description of the desired functionality. This means your response shoudl start with the keyword param.
"@
        $expectScriptBlock = $true
    } else {
    }

    $requirementsPrompt =
    @"
Your entire response must be a valid fragment of code in the language $($Language). You must not embed the code in markdown formatting. This means the response must not start with ``` or end with ```. You may include explanation of the code, but only as comments valid in the specified language. If you have the ability to search the internet for examples of code that satisfies the user's request, you may perform the search and incorporate ideas from the search results into the result that you generate.
"@

    $codeGenerationSystemPrompt = $basePrompt + "`n" +
        $specializedPrompt + "`n" +
        $requirementsPrompt

    $codeText = $null

    $scriptBlock = $null

    $languageException = $null

    for ( $retries = 0; $retries -lt $MaxRetries; $retries++ ) {
        $responseText = $targetSession.SendStandaloneMessage($Definition, $codeGenerationSystemPrompt, $AllowAgentaccess.IsPresent)

        $codeText = if ( $expectScriptBlock ) {
            $responseText.TrimStart('{').TrimEnd('}')
        } else {
            $codeText
        }

        if ( $codeText -and $isPowerShell ) {
            try {
                $scriptBlock = [ScriptBlock]::Create($codeText)
            } catch {
                $languageException = $_
            }
        }

        if ( ! $languageException ) {
            break
        } else {
            continue
        }
    }

    if ( ! $languageException ) {
        if ( $isPowerShell -and ! $NoScriptBlock.IsPresent ) {
            $scriptBlock
        } else {
            $codeText
        }

        if ( $FunctionName ) {
            (. $__ChatGPS_ModuleParentFunctionBuilder $FunctionName $scriptBlock $Force.IsPresent ) | out-null
        }
    } else {
        write-error $languageException.Exception.Message
    }
}
