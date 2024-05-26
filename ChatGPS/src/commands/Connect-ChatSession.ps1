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

        [validateset('None', 'Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Summarize',

        [switch] $NoSetCurrent,

        [switch] $NoConnect,

        [switch] $NoProxy,

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
        $functionPrompt = [string] ([PromptBook]::GetFunctionPrompt($SystemPromptId))
        [PromptBook]::GetDefaultPrompt($SystemPromptId)
    }

    $targetProxyPath = if ( ! $NoProxy.IsPresent ) {
        "$psscriptroot\..\..\lib\AIProxy.exe"
    }

    $session = CreateSession $options -Prompt $targetPrompt -AiProxyHostPath $targetProxyPath -FunctionPrompt $functionPrompt -SetCurrent:(!$NoSetCurrent.IsPresent) -NoConnect:($NoConnect.IsPresent) -TokenStrategy $TokenStrategy

    if ( $PassThru.IsPresent ) {
        $session
    }
}
