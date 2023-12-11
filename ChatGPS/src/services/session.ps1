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

        [switch] $NoConnect
    )

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt, $functionPrompt)

    # This will force an actual connection and set the system prompt for the session
    if ( ! $NoConnect.IsPresent ) {
        SendMessage $session Hello | out-null
    }

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
        write-host 'function'
        $session.GenerateFunctionResponse($prompt)
    } else {
        write-host 'message'
        $session.GenerateMessageAsync($prompt)
    }

    $result = $response.Result

    if ( $response.Status -ne ([System.Threading.Tasks.TaskStatus]::RanToCompletion) ) {
        throw $response.Exception
    }

    $result
}
