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
Clears the session's conversation context history.

.DESCRIPTION
The Clear-ChatConversation command clears conversation history for a session, resetting it to the state it was in at session creation time, and this means that the command Get-ChatConversation will return no messages after this command is invoked. Clear-ChatConversation only clears the "current context" history shared between you and the language model; it has no impact on the log maintained in the session of all messages every sent to the model or received from it. The Clear-ChatLog command by contrast clears only the log and has no impact on the conversation context used in communication with the model.

The impact of invoking Clear-ChatConversation is that future model interactions will result in responses that have no "memory" of the conversation prior to running the Clear-ChatConversation command.

Clear-ChatConversation can be useful for the following use cases:

* You want to start a brand new conversation -- Clear-ChatConveration indeed does just that. You can still see your earlier messages using the Get-ChatLog command which is based on the log, not the current conversation context.
* You're experiencing long response times to your chat messages due to significant previous conversation history in the session. Clearing it with Clear-ChatConversation can dramatically speed up response times, at the expense of losing conversation history.
* The previous topics of conversation in the history are no longer relevant and may be negatively impacting the responses for newer topics in the session. Clearing the history will remove that potentially confusing context.
* You are using the session with automation that needs to repeatable; clearing the history with each iteration of the automation sets the conversation context to a known state increasing the likelihood of consistent interactions with the language model.

.PARAMETER Session
The session for which history should be cleared. If it is not specified, the current session is assumed.

.OUTPUTS
None.

.EXAMPLE
Clear-ChatConversation

This clears the current history context used when interacting with the language model.

.EXAMPLE
PS > Get-ChatConversation
 
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
PS > Clear-ChatConversation
PS > Get-ChatConversation
 
Count
-----
    0
 
PS > Get-ChatLog | Measure-Object | Select-Object Count
 
Count
-----
    6

This example demonstrates the Clear-ChatConversation only impacts the current conversation history (reflected in the change in the count of messages returned by Get-ChatConversation before and after using Clear-ChatConversation). The log remains even after Clear-ChatConversation is used, and this allows you to review previous messages even though they are no longer part of the interaction with the model.

.LINK
Get-ChatConversation
Get-ChatLog
Clear-ChatLog
Connect-ChatSession
#>
function Clear-ChatConversation {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
    }

    process {
        $targetSession = GetTargetSession $Session

        $targetSession.ResetHistory($true)
    }

    end {
    }
}
