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

<#
.SYNOPSIS
Clears the session's conversation history.

.DESCRIPTION
The Clear-ChatHistory command clears conversation history for a session, resetting it to the state it was in at session creation time. By default the command only clears the "current context" history shared between you and the language model; the session maintains a separate full "session history" comprising all exchanged messages, and that session history will not remain unless the FullContext parameter is specified.

Note that after using the ClearChat-History command, the Get-ChatHistory command will continue to show all previously exchanged messages unless the Clear-ChatHistory command is invoked with the FullHistory option, in which case Get-ChatHistory will show nothing.

* You're experiencing long response times to your chat messages due to significant previous conversation history in the session. Clearing it can dramatically speed up response times, at the expense of losing conversation history.
* The previous topics of conversation in the history are no longer relevant and may be negatively impacting the responses for newer topics in the session. Clearing the history will remove that potentially confusing context.
* You are using the session with automation that needs to repeatable; clearing the history with each iteration of the automation sets the conversation context to a known state increasing the likelihood of consistent interactions with the language model.

.PARAMETER Session
The session for which history should be cleared. If it is not specified, the current session is assumed.

.PARAMETER FullHistory
By default, only the current context of the conversation is cleared; the full history remains and it can be viewed with the Get-ChatHistory command. To fully remove this complete history which is no longer part of interactions with the language model, specify the FullHistory parameter.

.OUTPUTS
None.

.EXAMPLE
PS > Clear-ChatHistory

This clears the current history context used when interacting with the language model.

.EXAMPLE
PS > Get-ChatHistory -CurrentContextOnly
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
7/2/2025 7:29:30 PM      User                  0 what is the latest version of Semantic Kernel?
7/2/2025 7:29:33 PM      Assistant          2536 The latest version of Semantic Kernel available on NuGet
                                                 is version 1.59.0. If you would like more details or
                                                 links to the releases, let me know!
7/2/2025 7:29:42 PM      User                  0 Thank you.
7/2/2025 7:29:43 PM      Assistant           781 You're welcome! If you have any more questions or need
                                                 further assistance, feel free to ask. Have a great day!
7/2/2025 7:30:29 PM      User                  0 when was this latest version released?
7/2/2025 7:30:32 PM      Assistant          3370 The latest version of Semantic Kernel, version 1.59.0,
                                                 was released on July 1, 2025.
PS > Clear-ChatHistory
PS > Get-ChatHistory -CurrentContextOnly
PS >

In this example Get-ChatHistory was first executed with the CurrentContextOnly parameter to show multiple messages from active context used in communication with the language model. Then after Clear-ChatHistory is invoked, the same Get-ChatHistory command is repeated and this time no results are returned.

.LINK
Get-ChatHistory
Connect-ChatSession
#>
function Clear-ChatHistory {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [Switch] $FullHistory
    )

    begin {
        $targetSession = GetTargetSession $Session
    }

    process {
        $targetSession.ResetHistory(! $FullHistory.IsPresent)
    }

    end {
    }
}
