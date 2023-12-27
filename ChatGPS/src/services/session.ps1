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

        $functionPrompt = $null,

        [switch] $SetCurrent,

        [validateset('None','Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Truncate',

        [switch] $NoConnect
    )

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt, $TokenStrategy, $null, $functionPrompt)

    if ( $SetCurrent.IsPresent ) {
        if ( ( $script:Sessions | measure-object ).count -eq 0 ) {
            $script:Sessions.Add($session)
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

function SendMessage($session, $prompt, $forceChat) {
    $response = if ( $session.HasFunction -and ! $forceChat ) {
        $session.GenerateFunctionResponse($prompt)
    } else {
        $session.GenerateMessageAsync($prompt)
    }

    $result = $response.Result

    if ( $response.Status -ne ([System.Threading.Tasks.TaskStatus]::RanToCompletion) ) {
        throw $response.Exception
    }

    # Explicitly returning this *seems* to work around strange behavior with async. A better fix: get rid of async. :)
    $response.Result
}
