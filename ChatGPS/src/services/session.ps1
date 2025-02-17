#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [ordered] @{}
$CurrentSession = $null

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

        [string] $Name = $null,

        [string] $UserAgent,

        [switch] $NoSave,

        [switch] $Force
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

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $AiProxyHostPath, $Prompt, $TokenStrategy, $targetLogDirectory, $LogLevel, $null, $HistoryContextLimit, $context, $Name, $targetUserAgent)

    AddSession $session $SetCurrent.IsPresent $NoSave.IsPresent $Force.IsPresent

    $session
}

function AddSession($session, [bool] $setCurrent = $false, [bool] $noSave = $false, [bool] $forceOnNameCollision) {
    if ( ! $noSave ) {
        if ( $name ) {
            if ( $script:sessions.Count -gt 0 ) {
                $existing = $script:sessions.Values | where Name -eq $name

                if ( $existing ) {
                    if ( $forceOnNameCollision ) {
                        RemoveSession $existing $true
                    } else {
                        throw [ArgumentException]::new("A session named '$name' already exists.")
                    }
                }
            }
        }

        $script:sessions.Add($session.Id, $session)
    }

    if ( $setCurrent ) {
        $script:CurrentSession = $session
    }
}

function RemoveSession($session, $allowRemoveCurrent) {
    $current = GetCurrentSession

    $isCurrentSession = $current -and ( $current.id -eq $session.id )

    if ( $isCurrentSession -and ! $allowRemoveCurrent ) {
        throw [InvalidOperationException]::new("The session with identifier '$($session.Id)' may not be removed because it is the current active session.")
    }

    $script:sessions.Remove($session.Id)

    if ( $isCurrentSession ) {
        $script:CurrentSession = $script:sessions.Values | select-object -first 1
    }
}

function SetCurrentSession($session) {
    if ( $script:sessions[$session.id] ) {
        $script:CurrentSession = $session
    } else {
        throw [InvalidOperationException]::new("The specified session id='$($session.id)' name='$($session.name)' was not found in the current list of valid sessions.")
    }
}

function GetCurrentSession($failIfNotFound) {
    if ( $failIfNotFound -and (! $script:CurrentSession ) ) {
        throw "No current session exists -- use Connect-ChatSession to create a session"
    }

    $script:CurrentSession
}

function GetChatSessions {
    $script:sessions.Values
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

function RegisterSessionCompleter([string] $command, [string] $parameterName) {
    $sessionNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $sessions = GetChatSessions | where name -ne $null | sort-object name
        $sessions.Name | where { $_.StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
    }

    Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock $sessionNameCompleter
}
