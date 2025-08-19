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

<#
.SYNOPSIS
Gets the current conversation context of messages for a chat session interaction with a language model.

.DESCRIPTION
Get-ChatConversation a sequence of natural language messages and responses to those messages based on actual messages sent to the model and received as responses from it within a session. The messages in this sequence may not be the same as those that were actually sent and received since language models can process only a limited amount of text in a single interaction; to work around this limitation, ChatGPS commands like Send-ChatMessage or Start-ChatShell that interact with the model will compress longer conversations through strategies such as truncation or summarization, with the goal of preserving the overall meaning and context of the original conversation. The output of Get-ChatConveration is the result of such compressed context, though realistically this compression only occurs at a certain model-specific threshold, so shorter conversations will retain their full context.

The behavior of Get-ChatConversation constrasts with that of Get-ChatLog, which returns all messages ever exchanged, regardless of any conversation compression that occurs.

The Get-ChatConversation command is useful for understanding what context the language model is currently utilizing in responses; it is not useful though for a user experience that needs to show the history of all previous interactions. For displaying all of the exchanged messages or otherwise processing the conversation as it actually transpired, use the Get-ChatLog command instead.

.PARAMETER SessionName
Optional name of an existing session created by Connect-ChatSession or the settings infrastructure for which
history should be retrieved.

.PARAMETER Id
Optional session identifier of an existing session for which history should be retrieved.

.OUTPUTS
The command returns a collection of messages that represent a compressed view of all messages exchanged in the conversation such that the messages fit within the context of the model used in the session. For each message there is information about the source role of the message (e.g. the 'User' via a command like Send-ChatMessage or the language model labeled as 'Assistant'). Duration for receiving a response to the message is also returned. The message collection is ordered temporally.

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

In this example the sequence of messages sent by the User role via a command like Sent-ChatMessage with the response received from the Assitant role are displayed in the order in which they occured.

.EXAMPLE
Get-ChatConversation
 
PS > Get-ChatConversation | Measure-Object | Select-Object Count
 
Count
-----
    6
PS > Get-ChatLog | Measure-Object | Select-Object Count
 
Count
-----
    6
 
PS > Clear-ChatConversation
 
PS > Get-ChatConversation | Measure-Object | Select-Object Count
 
Count
-----
    0
PS > Get-ChatLog
 
Count
-----
    6

This example shows that Get-ChatConversation reflects only the current conversation history since the number of messages it returns changes to zero after Clear-ChatConversation is invoked, while the message count returned by Get-ChatLog is unchanged by the use of Clear-ChatLog.

.LINK
Clear-ChatConversation
Get-ChatLog
Clear-ChatLog
Connect-ChatSession
Select-ChatSession
#>
function Get-ChatConversation {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    [OutputType([Modulus.ChatGPS.Models.ChatMessage])]
    param(

        [parameter(parametersetname='byname', position=0)]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id
    )

    begin { }

    process {
        $nameOrId = if ( $SessionName ) {
            @{Name=$SessionName}
        } elseif ( $Id )  {
            @{Id=$Id}
        } else {
            @{Id=(Get-ChatSession -Current).Id}
        }

        $targetSession = Get-ChatSession @nameOrId

        foreach ( $message in $targetSession.CurrentHistory ) {
            if ( $message.Role.ToString() -ne 'system' ) {
                $message
            }
        }
    }

    end { }
}

RegisterSessionCompleter Get-ChatConversation SessionName
RegisterSessionCompleter Get-ChatConversation Id
