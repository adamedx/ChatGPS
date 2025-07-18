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
Gets the conversation history of messages for a chat session interaction with a language model.

.DESCRIPTION
Get-ChatHistory returns the sequence of natural language messages sent by ChatGPS commands to the language model along with each resulting response from the model. Commands such as Send-ChatMessage or Start-ChatShell are used to send messages to the language model in the context of a session where the latest message is interpreted by the language model using the context of previously sent messages in the session, just as in a two-person human conversation. By default Get-ChatHistory shows all messages sent and received between the command and the language model since the creation of the session. Because language models have limits on the amount of previous conversation history that can be processed as context as the conversation session progresses, the entire conversation history may not be visible to the language model. To see the history of messages most recently utilized by the language model, the CurrentContextOnly parameter may be specified.

Typically in the early stages of a conversation the results returned by Get-ChatHistory with and without the CurrentContextOnly parameter are identical; it is only after sufficient conversation history is accumulated and its size exceeds that which can be processed by the model that the context is compressed to a size that fits within the model's processing limits. At this point specification of the CurrentContextOnly will indeed deviate from the results without it.

Note that when the CurrentContextOnly parameter is specified, not only can the resulting list of messages be a subset of the full list returned without this parameter, each individual message may be altered as well, typically changed to contain compressed summaries of multiple messages. The behavior of message compression will differ depending on the behavior for the session specified when the session we created with the Connect-ChatSession command. See the documentation for Connect-ChatSession and the TokenStrategy parameter of that command for more details.

.PARAMETER SessionName
Optional name of an existing session created by Connect-ChatSession or the settings infrastructure for which
history should be retrieved.

.PARAMETER Id
Optional session identifier of an existing session for which history should be retrieved.

.PARAMETER CurrentContextOnly
Optional parameter to display only the messages currently used as context when exchanging messages with the language model. By default, all messages are returned verbatim as they were sent and received. To override the default, specify CurrentContextOnly to obtain messages that represent a compressed form of the total set of messages exchanged when such compression is required to fit within the processing limits of the language model.

.OUTPUTS
The command returns a collection of messages that include information about the source role of the message (e.g. the 'User' via a command like Send-ChatMessage or the language model labeled as 'Assistant'). Duration for receiving a response to the message is also returned. The message collection is ordered temporally.

.EXAMPLE
PS > Get-ChatHistory
 
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

.LINK
Clear-ChatSession
Connect-ChatSession
Select-ChatSession
#>
function Get-ChatHistory {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    [OutputType([Modulus.ChatGPS.Models.ChatMessage])]
    param(

        [parameter(parametersetname='byname', position=0)]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [Switch] $CurrentContextOnly
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

        $targetHistory = if ( $CurrentContextOnly.IsPresent ) {
            $targetSession.CurrentHistory
        } else {
            $targetSession.History
        }

        foreach ( $message in $targetHistory ) {
            if ( $message.Role.ToString() -ne 'system' ) {
                $message
            }
        }
    }

    end { }
}

RegisterSessionCompleter Get-ChatHistory SessionName
RegisterSessionCompleter Get-ChatHistory Id
