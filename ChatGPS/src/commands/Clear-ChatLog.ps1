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
Clears the log of the messages exchnaged in the session.

.DESCRIPTION
The Clear-ChatLog command clears conversation message log for a session, resetting it to the state it was in at session creation time; it does not affect the current conversation context. This behavior differs from that of the related command Clear-ChatConversation which leaves the message log untouched but clears the current conversation context used by the session.

Because this command acts on the log and not current conversation context, it has no impact on future interactions with the model; the response received from subsequent communication with the model will be the same as if the command had not executed.

The log differs from the conversation history context in that it retains the full content of every message sent and received by the session, except of course when those messages are cleared by Clear-ChatLog. This is useful for reviewing all previous exchanges to understand or present all previous interactions as they were experienced by the user. By contrast, the conversation history context is dynamic as the language model has a fixed context window and thus ongoing conversations must be "compressed" from time to time as the conversation continues through techniques such as summarization.

This means that the greater the length of the conversation text, the more likely it is that the conversation history context will be shorter than the log, since the former must eventually be shortened and the latter only grows with each message.

It also means that Clear-ChatLog will have no impact on future messages exchnaged in the session, since the log is not used in language model interactions, only the conversation history context is used, and that is not affected by Clear-ChatLog. The command Get-ChatConversation for instance will continue to show the current converation context used for model interactions even after Clear-ChatLog is invoked.

Clear-ChatLog is useful for freeing memory resources for instance for very long conversations when the long-term log is not useful.

.PARAMETER Session
The session for which the log should be cleared. If it is not specified, the current session is assumed.

.OUTPUTS
None.

.EXAMPLE
Clear-ChatLog

This clears the log of the current session.

.EXAMPLE
PS > Get-ChatLog
 
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
PS > Clear-ChatLog
PS > Get-ChatLog | Measure-Object | Select-Object Count
 
Count
-----
    0
 
PS > Get-ChatConversation | Measure-Object | Select-Object Count
 
Count
-----
    6

This example shows that using Clear-ChatLog does impact the log by clearing it to zero entries, but has no effect on the current conversation, which continues to showw a non-zero number of messages.


.LINK
Get-ChatLog
Get-ChatConversation
Clear-ChatConversation
Connect-ChatSession
#>
function Clear-ChatLog {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
    }

    process {
        $targetSession = GetTargetSession $Session
        $targetSession.ResetHistory($false)
    }

    end {
    }
}
