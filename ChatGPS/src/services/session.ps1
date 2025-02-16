#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [System.Collections.ArrayList]::new()

$__ModuleVersionString = {}.Module.Version.ToString()

function GetUserAgent {
    $osversion = [System.Environment]::OSVersion.version.tostring()
    $platform = 'Windows NT'
    $os = 'Windows NT'
    if ( $PSVersionTable.PSEdition -eq 'Core' ) {
        if ( ! $PSVersionTable.OS.contains('Windows') ) {
            $platform = $PSVersionTable.Platform
            if ( $PSVersionTable.OS.contains('Linux') ) {
                $os = 'Linux'
            } else {
                $os = [System.Environment]::OSVersion.Platform
            }
        }
    }
    $language = [System.Globalization.CultureInfo]::CurrentCulture.name
    'Modulus-ChatGPS/{5} PowerShell/{4} ({0}; {1} {2}; {3})' -f $platform, $os, $osversion, $language, $PSVersionTable.PSversion, $__ModuleVersionString
}

function CreateSession {
    param(
        [parameter(mandatory=$true)]
        [Modulus.ChatGPS.Models.AiOptions] $Options,

        [parameter(mandatory=$true)]
        [string] $Prompt,

        [string] $AiProxyHostPath = $null,

        [string] $LogDirectory = $null,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel = 'Default',

        [switch] $SetCurrent,

        [validateset('None','Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Truncate',

        [switch] $NoConnect,

        [int] $HistoryContextLimit = -1,

        [ScriptBlock] $SendBlock = $null,

        [ScriptBlock] $ReceiveBlock = $null,

        [string] $UserAgent
    )

    $targetLogDirectory = if ( $LogDirectory ) {
        (Get-Item $LogDirectory).FullName
    }

    $context = @{
        SendBlock = $SendBlock
        ReceiveBlock = $ReceiveBlock
    }

    $targetUserAgent = if ( $UserAgent ) {
        $UserAgent
    } else {
        GetUserAgent
    }

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $AiProxyHostPath, $Prompt, $TokenStrategy, $targetLogDirectory, $LogLevel, $null, $HistoryContextLimit, $context, $targetUserAgent)

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
