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

        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true,mandatory=$true)]
        [Uri] $ApiEndpoint,

        [parameter(valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [string] $ModelIdentifier,

        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true,mandatory=$true)]
        [string] $ApiKey,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [int32] $TokenLimit = 4096,

        [parameter(parametersetname='localmodel', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [string] $LocalModelPath,

        [validateset('None', 'Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Summarize',

        [string] $LogDirectory = $null,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel = 'Default',

        [switch] $NoSetCurrent,

        [switch] $NoConnect,

        [switch] $NoProxy,

        [switch] $PassThru
    )

    $options = [Modulus.ChatGPS.Models.AiOptions]::new()

    $options.ApiEndpoint = $ApiEndpoint
    $options.ModelIdentifier = $ModelIdentifier
    $options.ApiKey = $ApiKey
    $options.TokenLimit = $TokenLimit
    $options.LocalModelPath = $LocalModelPath

    if ( $options.LocalModelPath ) {
        $options.Provider = 'LocalOnnx'
    } else {
        $options.Provider = 'AzureOpenAI'
    }

    $functionInfo = $null
    $functionDefinition = $null
    $functionParameters = $null

    $targetPrompt = if ( $Prompt ) {
        $Prompt
    } else {
        $functionInfo = ([PromptBook]::GetFunctionInfo($SystemPromptId))
        [PromptBook]::GetDefaultPrompt($SystemPromptId)
    }

    if ( $functionInfo ) {
        $functionParameters = [string] $functionInfo.Parameters
        $functionDefinition = [string] $functionInfo.Definition
    }

    $targetProxyPath = if ( ! $NoProxy.IsPresent ) {
        "$psscriptroot\..\..\lib\AIProxy.exe"
    }

    $session = CreateSession $options -Prompt $targetPrompt -AiProxyHostPath $targetProxyPath -FunctionPrompt $functionDefinition -FunctionParameters $functionParameters -SetCurrent:(!$NoSetCurrent.IsPresent) -NoConnect:($NoConnect.IsPresent) -TokenStrategy $TokenStrategy -LogDirectory $LogDirectory -LogLevel $LogLevel

    if ( $PassThru.IsPresent ) {
        $session
    }
}
