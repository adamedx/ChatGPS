#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [System.Collections.ArrayList]::new()

function CreateSession {
    param(
        [parameter(mandatory=$true)]
        [Modulus.ChatGPS.Models.AiOptions] $Options,

        [parameter(mandatory=$true)]
        [string] $Prompt,

        [string] $AiProxyHostPath = $null,

        [string] $FunctionPrompt = $null,

        [string[]] $FunctionParameters = $null,

        [string] $LogDirectory = $null,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel = 'Default',

        [switch] $SetCurrent,

        [validateset('None','Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Truncate',

        [switch] $NoConnect,

        [int] $HistoryContextLimit = -1,

        [ScriptBlock] $SendBlock = $null,

        [ScriptBlock] $ReceiveBlock = $null
    )

    $targetLogDirectory = if ( $LogDirectory ) {
        (Get-Item $LogDirectory).FullName
    }

    $context = @{
        SendBlock = $SendBlock
        ReceiveBlock = $ReceiveBlock
    }

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $AiProxyHostPath, $Prompt, $TokenStrategy, $functionPrompt, $functionParameters, $targetLogDirectory, $LogLevel, $null, $HistoryContextLimit, $context)

    if ( $SetCurrent.IsPresent ) {
        if ( ( $script:Sessions | measure-object ).count -eq 0 ) {
            # Did you know ArrayList.Add() returns output? -- don't let it into the pipeline!
            $script:Sessions.Add($session) | out-null
        } else {
            $script:Sessions[0] = $session
        }
    }

    $session
}

function GetCurrentSession($failIfNotFound) {
    $session = if ( ( $script:Sessions | measure-object ).count -ne 0 ) {
        $script:Sessions[0]
    }

    if ( $failIfNotFound -and (! $session ) ) {
        throw "No current session exists -- use Connect-ChatSession to create a session"
    }

    $session
}

function GetTargetSession($userSpecifiedSession, [bool] $failIfNotFound = $false) {
    $targetSession = if ( $userSpecifiedSession ) {
        $userSpecifiedSession
    } else {
        GetCurrentSession
    }

    if ( $failIfNotFound -and (! $targetSession ) ) {
        throw "No current session exists -- use Connect-ChatSession to create a session"
    }

    $targetSession
}

function SendMessage($session, $prompt, $functionDefinition) {
    $sendBlock = GetSendBlock $session

    $targetPrompt = if ( ! $sendBlock ) {
        $prompt
    } else {
        $sendBlock.Invoke($prompt)
    }

    $response = if ( $functionDefinition ) {
        $session.GenerateFunctionResponse($functionDefinition, $targetPrompt)
    } else {
        $session.GenerateMessage(@($targetPrompt))
    }

    $receiveBlock = GetReceiveBlock $session

    if ( ! $receiveBlock ) {
        $response
    } else {
        $processedResponse = $receiveBlock.Invoke(@($response))
        $session.UpdateLastResponse($processedResponse)
        $processedResponse
    }
}

function GetSendBlock($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['SendBlock']
    }
}

function GetReceiveBlock($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['ReceiveBlock']
    }
}
