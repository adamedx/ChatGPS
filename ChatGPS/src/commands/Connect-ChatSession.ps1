#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Connect-ChatSession {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [string] $Prompt,

        [validateset('PowerShell', 'PowerShellStrict', 'General', 'Conversational')]
        [string] $SystemPromptId = 'PowerShell',

        [parameter(valuefrompipelinebypropertyname=$true,mandatory=$true)]
        [Uri] $ApiEndpoint,

        [parameter(valuefrompipelinebypropertyname=$true,mandatory=$true)]
        [string] $ModelId,

        [parameter(valuefrompipelinebypropertyname=$true,mandatory=$true)]
        [string] $ApiKey,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [int32] $TokenLimit = 4096,

        [validateset('None', 'Truncate')]
        [string] $TokenStrategy = 'Truncate',

        [switch] $NoSetCurrent,

        [switch] $NoConnect,

        [switch] $PassThru
    )

    $options = [Modulus.ChatGPS.Models.AiOptions]::new()

    $options.ApiEndpoint = $ApiEndpoint
    $options.ModelIdentifier = $ModelId
    $options.ApiKey = $ApiKey
    $options.TokenLimit = $TokenLimit

    $functionPrompt = $null

    $targetPrompt = if ( $Prompt ) {
        $Prompt
    } else {
        $functionPrompt = [PromptBook]::GetFunctionPrompt($SystemPromptId)
        [PromptBook]::GetDefaultPrompt($SystemPromptId)
    }

    $session = CreateSession $options -Prompt $targetPrompt -FunctionPrompt $functionPrompt -SetCurrent:(!$NoSetCurrent.IsPresent) -NoConnect:($NoConnect.IsPresent)

    if ( $PassThru.IsPresent ) {
        $session
    } else {
        for ( $i = 0; $i -lt 3; $i++ ) {
            # Workaround for apparent race condition
            try {
                $session.History | select-object -last 1 | select-object -expandproperty Content
                break
            } catch {
                start-sleep 1
            }
        }
    }
}
