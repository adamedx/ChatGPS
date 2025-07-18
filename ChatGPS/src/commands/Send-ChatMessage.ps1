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
Sends a message with conversation context to a language model and returns the response from the model.

.DESCRIPTION
The Send-ChatMessage sends a specified message to the language model for and receives a response which is returned as the command's output.

Additionally, the message sent to the language model is added to the chat session's conversation history as the latest message, and then response from the language model is added after it. The language model's response takes into account previous conversation history. Messages sent by the user as well as those returned by the model will typically use natural language. The capability to return responses to user-specified messages is commonly known as "chat completions" as the model is simply predicting or "completing" the chat history with the most likely response based on its trained understanding of the way in which human conversations typically proceed.

Messages are communicated within the context of a chat session created by the Connect-ChatSession command. Sessions not only define the location of the model and associated access information such as credentials, but also maintain the conversation history of messages sent to the model and received from it. For more information about chat sessions, see the Connect-ChatSession command.

Send-ChatMessage provides facilities for formatting the response returned by the command. It also allows the optional specification of script blocks to process messages before they are sent to the model, and also to process responses received from the model. The ReplyBlock feature also allows the command to automatically send a new request to the model as a reply to the model's response.

.PARAMETER Message
The message to send to the language model. This can be natural language, or a programming language, or semi-structured data, or really any text contextualized by the chat session's system prompt. The language model will return a response based on this message as well as the previous conversation history.

.PARAMETER FunctionDefinition
The FunctionDefinition parameter allows for an optional natural language function to be applied to the message before it is sent to the model. The function definition must have a parameter named "input" which receives the value of the Message parameter. Note that invocation of the function will involve communication with the language model. For more information on how to define a function, see the New-ChatFunction command.

.PARAMETER OutputFormat
Specifies formatting that should be applied to the response before it is returned as the result of the command. The default value of "None" returns the response as-is. A value of Markdown will result the Show-Markdown comand being applied to the output, and PowerShellEscaped replaces the escaped version of the escape character, i.e. '`e` with the unescaped value.

.PARAMETER ReceiveBlock
Specify a script block for ReceiveBlock to process the response received from the model. The first parameter of the script block is the model's response, and the script block can then return a result based on the response. One possible use for this parameter is to add formatting to the response for instance.

.PARAMETER ReplyBlock
Specify a script block for ReplyBlock that, like ReceiveBlock, receives a response from the model after a response is received, and unlike ReceiveBlock, a non-null output from ReplyBlock is sent to the model as if it had been sent by the user. This can be used for automation scenarios.

.PARAMETER MaxReplies
MaxReplies is used to control the number of times the script in ReplyBlock will be executed during the current invocation of Send-ChatMessage. This can be used to limit unattended usage of the model or otherwise bound runaway interactions with the language model

.PARAMETER Session
Specifies the chat session through which the message will be sent. By default, the current session is used.

.PARAMETER RawOutput
Specify RawOutput so that Send-ChatMessage sends only the verbatim output from the language model. By default, the output is in the form of message objects which include the model's response as a field.

.PARAMETER NoOutput
Specify NoOutput to prevent output from being emitted by the command; by default, the response from the language model is output. This is useful if you simply want to capture the model's response in the session conversation history, but don't need to see or process the result.

.PARAMETER NoReplyOutput
When ReplyBlock is specified, it is normally emitted as output so that output reflects conversation history since Send-ChatMessage was invoked. To disable this and only show responses from the model, specify this parameter.

.PARAMETER MessageSound
Specify this parameter so that a sound is played when a response is received from the language model.

.PARAMETER SoundPath
When MessageSound is true, SoundPath provides a path to the sound, e.g. a wave file or other sound file, to be played audibly when a message is received.


.OUTPUTS
A message object that contains the response from the language model. The message object contains specific properties for the message text, the time at which the message was received, the sender of the message, etc. If the RawOutput options is specified however then instead of an object, only the message text is emitted.

.EXAMPLE
Send-Chat Hello

Received                 Response
--------                 --------
3/11/2025 10:10:16 PM    Hello! How can I assist you today?

Send-ChatMessage is used to send a greeting message of "Hello", and an appropriate response is returned by the language model. The time of the response as well as its content is part of the output of Send-ChatMessage and both are rendered by default to the console.

.EXAMPLE
Connect-ChatSession -SystemPromptId Terse -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini
PS > Send-ChatMessage 'What attribute do I use to define a specific set of values for the parameter of a Powershell function?'
 
Received                 Response
--------                 --------
7/17/2025 10:46:35 PM    Use the `[ValidateSet()]` attribute to define
                         a specific set of allowed values for a
                         PowerShell function parameter.

This example creates a new connection using the 'Terse" system prompt Id to get a more concise than is typical for this model, demonstrating that Send-ChatMessage is highly dependent on the chat session's system prompt and other settings. To reduce the need to provide explicit instructions for each message sent with Send-ChatMessage it can be convenient to choose a specific system prompt to impact the session as a whole.
 
.EXAMPLE
Send-ChatMessage 'Can you generate concise Python code to issue an HTTP GET request?' | Select-Object  Content
 
Content
-------
Sure! Here's a concise version of the Python code to issue an HTTP GET request:ª
 
```python
import requests
 
response = requests.get('https://api.example.com/data')
print(response.json() if response.status_code == 200 else response.status_code)
```
  PS > Send-ChatMessage 'Can you show Python code that will issue an HTTP GET request?' | Select-Object Content
 
Content
-------
import requests
 
response = requests.get('https://api.example.com/data')
print(response.json() if response.status_code == 200 else response.status_code)

In this example multiple chat message are exchanged; notice that subsequent chat messages assume the previous requests and responses as context, so the user can refine previous requests to get a better answer as in this case, and in general interact through "human-like" exchanges of dialogue. When you do need to clear the context and start a conversation from the beginning, use the Clear-ChatHistory command.

.EXAMPLE
$response = Send-ChatMessage "Can you return all the scores of yesterday's NBA games as JSON? The structure should be an array of game element that represents the score of the game. The game element should have a two keys, one called Team1, the other called Team2, and the value of each key should be the name of each of the teams in a game. There should be two other keys in the game element, one called Score1 the other called Score2, and the value of each key should be the score of each team in that game. Only return JSON, do not return markdown or explanatory text."
 
PS > $response | Select-Object -ExpandProperty Response | ConvertFrom-Json
 
Team1           Team2                 Score1 Score2
-----           -----                 ------ ------
Orlando Magic   Golden State Warriors    115    121
Chicago Bulls   Los Angeles Lakers       107    108
Miami Heat      Boston Celtics           116    123
Brooklyn Nets   New York Knicks          112    110
Denver Nuggets  Phoenix Suns             123    120
Milwaukee Bucks Toronto Raptors          121    113

.EXAMPLE
This example demonstrates how to use the output of Send-ChatMessage with other commands for additional processing. In this case a more complex prompt was supplied. The example assumes that a plugin such as Bing or Google was added to the session with the Add-ChatPlugin command, and the AllowAgentAccess property of the session was set to true. The prompt supplied to Send-ChatMessage instructed the model to use web search to find the scores of games and represent them as JSON. The Content property of the output of Send-ChatMessage is then piped to Convert-FromJson which is able to successfully deserialize the JSON, and a well-formatted result of the scores is presented to the terminal.


.LINK
Connect-ChatSession
Start-ChatShell
Clear-ChatHistory
#>
function Send-ChatMessage {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true, valuefrompipeline=$true)]
        [string] $Message,

        [string] $FunctionDefinition,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat,

        [ScriptBlock] $ReceiveBlock,

        [ScriptBlock] $ReplyBlock,

        [int32] $MaxReplies = 1,

        [Modulus.ChatGPS.Models.ChatSession]
        $Session,

        [switch] $RawOutput,

        [switch] $NoOutput,

        [switch] $NoReplyOutput,

        [switch] $MessageSound,

        [string] $SoundPath
    )

    begin {
        $currentReplies = $MaxReplies

        $formatParameters = GetPassthroughChatParams -AllParameters $PSBoundParameters

        $targetSound = if ( $MessageSound.IsPresent -and $PSVersionTable.Platform -eq 'Win32NT' ) {
            $targetSoundPath = if ( $SoundPath ) {
                $SoundPath
            } else {
                join-path $env:windir 'media/windows menu command.wav'
            }

            [System.Media.SoundPlayer]::new($targetSoundPath)
        }

        $messageFunction = if ( $FunctionDefinition ) {
            $function = New-ChatFunction $FunctionDefinition

            $parameters = $function | Get-ChatFunction | select-object -expandproperty Parameters

            if ( ! ( $parameters.keys -contains 'input' ) ) {
                throw [ArgumentException]::new("The specified function does not contain the mandatory parameter named 'input'")
            }

            $FunctionDefinition
        }

        $targetSession = GetTargetSession $Session

        SendConnectionTestMessage $targetSession $true
    }

    process {

        $currentMessage = $message

        while ( $currentMessage ) {

            write-progress "Sending message" -percentcomplete 35

            $response = SendMessage $targetSession $currentMessage $messageFunction

            write-progress "Response received, transforming" -percentcomplete 70

            $responseInfo = $targetSession.History | select -last 1

            if ( ! $NoOutput.IsPresent ) {
                $responseObject = $response | ToResponse -role $responseInfo.Role -Received $responseInfo.Timestamp
                $transformed = $responseObject | TransformResponseText @formatParameters
                if ( ! $RawOutput.IsPresent ) {
                    if ( $responseObject ) {
                        $transformed | ToResponse -role $responseObject.Role -Received $responseObject.Received
                    }
                } else {
                    $transformed
                }

                if ( $targetSound ) {
                    $targetSound.Play()
                }
            }

            write-progress "Processing optional reply" -percentcomplete 80

            $replyData = GetChatReply -SourceMessage $response -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

            $currentMessage = if ( $replyData ) {
                $currentReplies = $replyData.NextMax
                $replyData.Reply
            }

            if ( ( ! $NoOutput.IsPresent ) -and ( ! $NoReplyOutput.IsPresent ) -and $currentMessage ) {
                $currentMessage | ToResponse -role User -Received ([DateTime]::now)
                if ( $targetSound ) {
                    $targetSound.Play()
                }
            }

            write-progress "Processing completed" -percentcomplete 100 -completed
        }
    }

    end {
    }
}
