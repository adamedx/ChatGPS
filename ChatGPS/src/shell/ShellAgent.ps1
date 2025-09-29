#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function GetClientContext($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['ClientContext']
    }
}

function GetShellAgentStatus($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['ShellAgentEnabled']
    }
}

function SetShellAgentStatus($session, [bool] $enabled) {
    if ( ! $session.CustomContext ) {
        throw [InvalidOperationException]::new("The agent cannot be enabled because the session has no context")
    }

    $session.CustomContext['ShellAgentEnabled'] = $enabled
}

function GetTranscriptCount {
    (get-chatsession |
      where { $_.customcontext['ShellAgentEnabled'] -and
              $_.customcontext['ClientContext'].TranscriptPath } |
                measure-object).Count
}

function UpdateClientContext($session, $transcriptPath = $null, [switch] $ForgetTranscript) {
    $clientContext = GetClientContext $session

    if ( $clientContext ) {
        if ( $ForgetTranscript.IsPresent ) {
            if ( $transcriptPath ) {
                throw [ArgumentException]::new("A transcript path was specified at the same time the ForgetTranscript option was specified")
            }

            $clientContext.TranscriptPath = $null
        } elseif ( $transcriptPath ) {
            $clientContext.TranscriptPath = $transcriptPath
        }

        $clientContext.CurrentDirectory = (Get-Location).Path

        $clientContext.Update($clientContext)
    } elseif ( $transcriptPath ) {
        throw [InvalidOperationException]::new("The transcript directory cannot be updated because there is not client context")
    }
}

function GetTranscriptDirectory {
    '~/.chatgps/session/AgentTranscripts'
}

function GetTranscriptPathFromIds {
    param(
        [string] $transcriptDirectory,

        [string] $sessionId,

        [int] $ProcessId = 0,

        [switch] $MatchAll
    )

    $prefix = 'AgentTranscript-'

    $targetProcessId = if ( 0 -eq $ProcessId ) {
        $PID
    } else {
        $processId
    }

    $transcriptRelativePath = if ( ! $MatchAll.IsPresent ) {
        "$($prefix)PID=$($targetProcessId)-$($__PS_ChatGPS_Session_Id)).txt"
    } else {
        "$($prefix)*.txt"
    }

    join-path $transcriptDirectory $transcriptRelativePath
}

function GetAgentTranscriptPath($session) {
    $context = GetClientContext $session

    if ( $context ) {
        $context.TranscriptPath
    } else {
        throw [InvalidOperationException]::new("The transcript for the specified session cannot be retrieved because it does not contain a client context")
    }
}

