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
The Start-ChatShell command provides an ongoing interactive chat loop interface, i.e. a Read-Eval-Print-Loop (REPL) for extended conversations purely using natural language without the need to adhere to PowerShell command syntax. It functions as an interactive implementation of Send-ChatMessage with an emphasis on continous natural language interactions with the language model.

Start-ChatShell presents the user with a prompt, and when the user enters a line of text in presonse, that text is sent to the model as if it had been sent by the Send-ChatMessage command. Once a response is received, it is displayed to the user and then the user can enter additional text.

Thus Start-ChatShell provides an experience analogous to many "chatbots" that enable interactions with language models, treating the models as if they were humans rather than software.

In addition to natural language input, the REPL supports a small number of simple "shell commands" that allow basic interactions outside of natural language. Shell commands are prefixed with a "." and must be the first non-whitespace character of any line of text entered by the user for the command to be executed correctly.

The '.exit' command ends the Start-ChatShell command (CTRL-C may also be used). Use the '.help' command to list all of the shell commands, including '.history' to review previous messages in the chat and '.last' to see the last response again.

Start-ChatShell continues indefinitely until the user chooses to terminate the command by entering the '.exit' shell command.

Conversations conducted with Start-ChatShell occur in the context of a chat session, just as messsages from Send-ChatMessage and their replies do. In fact, the same chat session can contain messages from both Send-ChatMessage and Start-ChatShell, and because of this, the user can freely exist Start-ChatShell and then use Send-ChatMessage where it will include the context from the messages exchanged in Start-ChatShell when interacting with the model, and on returning to Start-ChatShell the messages from Send-ChatMessage will also be part of the context in the REPL. Both commands contribute to the same session which has a single conversation history shared by all commands, and this allows for changes in conversation mode as needed without the loss of context.

Note that the conversation settings of Connect-ChatSession influence the behavior of Start-ChatShell and Send-ChatMessage in the same way, including adherence to the system prompt and any receive blocks specified to the session.

Plugins added to the session impact conversations in Start-ChatShell just as they do Send-ChatMessage, so your conversation with the model can take advantage of plugins that access web search engines, the local file system, any custom plugin functionality you define with Register-ChatPlugin, etc.

To reset conversation context used by Start-ChatShell, the '.clearhistory' shell command can be used from Start-ChatShell, and it has the same impact as the Clear-ChatHistory command. Alternatively, the Clear-ChatHistory command can be invoked explicitly.

.PARAMETER InitialPrompt
Specify InitialPrompt so that the repl starts with a request to the language model, waiting for a response and displaying it before prompting the user and waiting for input. By default, when Start-ChatShell is invoked it is waiting for input before sending any input to the language model.

.PARAMETER FunctionDefinition
Specifies a natural language function to be invoked whenever the user enters text. It must have one argument named 'Input'; it is the user's text input. The result of the function will be the response. For more information on natural language functions, see the New-ChatFunction command documentation.

.PARAMETER FunctionName
Specifies the name of a natural language function that was created with New-ChatFunction. It must conform to the requirements of FunctionDefinition.

.PARAMETER FunctionId
Specifies the id of a natural language function that was created with New-ChatFunction. It must conform to the requirements of FunctionDefinition.

.PARAMETER OutputFormat
Specifies processing that should be applied to the response from the language model. The default value of 'None' means no processing will be applied. The value 'Markdown' means that the response will be interpreted as output and processed to produce markdown formatting using the Show-Markdown command. The value 'PowerShellEscaped' will result in the response being evaluated as a PowerShell interpolated string so that expressions like '`n' and '`t' will be transformed into newline and tab characters respectively.

.PARAMETER PromptHint
Specifies the text of the prompt displayed by the Start-ChatShell when waiting for user input. Start-ChatShell has a default prompt, specify this parameter to override it.

.PARAMETER HideInitialPrompt
By default, when InitialPrompt is specified, it is shown in the repl; specify this parameter to hide it.

.PARAMETER HideInitialResponse
By default, the last response from the language model is shown shown when Start-ChatShell starts before asking for user input so the user has context on what the last response was in the conversation. To hide this response, specify HideInitialResponse

.PARAMETER HidePromt
By default, Start-ChatRepl shows a prompt every time it is ready for the user to enter input. Specify HidePrompt so that no prompt is shown.

.PARAMETER NoOutput
By default, responses are echoed to the terminal. Specify NoOutput so that the response will not be emitted to the terminal; it will still be present in the chat session history, and the response will still be processed by the script block from ReceiveBlock if it is specified.

.PARAMETER RawOutput
By default, responses from the language model are output as structured formatted text. To the response exactly as the language model returned it, specify RawOutput.

.PARAMETER NoWelcome
By default, Start-ChatShell displays a welcome message the first time it is executed within a PowerShell session. Specify this parameter so that no welcome message is displayed.

.PARAMETER ShowWelcome
By default, Start-ChatShell will only show a welcome message the first time it is executed within a Powershell session, but to force the banner to be displayed specify the ShowWelcome parameter.

.PARAMETER ReceiveBlock
Specify a script block for ReceiveBlock to process the response from the language model and alter the output that will be emitted by Start-ChatShell. See the documentation for the ReceiveBlock parameter of the Send-ChatMessage command for details.

.PARAMETER UserReplyBlock
Specify this parameter to send an automated reply to the language model based on its last response. See the ReplyBlock parameter of the Send-ChatMessage command.

.PARAMETER MaxReplies
See the MaxReplies parameter of the Send-ChatMessage command which has the same semantics associated with UserReplyBlock.

.PARAMETER NoAutoConnect
By default, if there is no chat session connected by Connect-ChatSession Start-ChatShell will attempt to connect a default session. Specify NoAutoConnect to prevent this; in that scenario, the command will fail and Connect-ChatSession will need to be invoked before retrying Start-ChatShell with this parameter enabled.

.PARAMETER MessageSound
An experimental parameter that provides audible feedback to signal the arrival of a response from the language model. The sound to be played is specified by the SoundPath parameter.

.PARAMETER AllowInitialReceiveBlock
By default, when the initial response is emitted at the start of the command prior to user input, the script block specified by ReceiveBlock is not invoked. To override this behavior and allow the receive block to be executed, specify AllowInitialReceiveBlock.

.PARAMETER SplashTitle
When the welcome message is displayed by Start-Shell on first launch, it will include a "splash" banner. By default the 'Normal' splash banner is shown when the value of SplashTitle is 'Normal'. If it is 'Large', a larger splash is shown.

.PARAMETER SoundPath
An experimental feature that specifies the path for the sound to be played when MessageSound is specified.

.PARAMETER Session
Specifies the chat session on which to repl conversation will occur.

.OUTPUTS
The command itself has no output since any output from perceived by the user is actually written directly to the terminal's standard output rather than emitted to the PowerShell pipeline. To access language model responses via the pipeline, use the Send-ChatMessage command instead.

.EXAMPLE
Start-ChatShell
 
(morpheus) ChatGPS>: hello
 
Received                 Response
--------                 --------
2/9/2025 7:53:47 PM      Hello! How can I assist you today?

When executed with no arguments, the user is presented with a prompt and receives a typical response from the language model.

.EXAMPLE
chatgps
 
(ryu) ChatGPS>: Can you translate this Chinese text to English? 我要坐哪个火车去机场？
 
Received                 Response
--------                 --------
7/19/2025 10:08:04 PM    The translation of the Chinese text "我要坐哪个火车去机场？" to English
                         is "Which train should I take to the airport?"
 
(ryu) ChatGPS>: Thanks! Can you tell me if my grammar was correct in that last Chinese text I submitted?
 
7/19/2025 10:21:01 PM    Yes, your grammar in the Chinese text "我要坐哪个火车去机场？" is correct.
                         The structure is clear, and the sentence conveys the meaning accurately.
 
                         - "我要" means "I want to."
                         - "坐" means "take" (as in taking a train).
                         - "哪个" means "which."
                         - "火车" means "train."
                         - "去" means "to."
                         - "机场" means "airport."
 
                         Overall, it's a well-constructed question!
 
(ryu) ChatGPS>: Thank you, that was very helpful.
 
7/19/2025 10:21:30 PM    You're welcome! I'm glad you found it helpful. If you have any more
                         questions or need assistance with anything else, feel free to ask!
 
(ryu) ChatGPS>: .exit

PS > chatgps
 
Received                 Response
--------                 --------
7/19/2025 10:21:30 PM    You're welcome! I'm glad you found it helpful. If you have any more
                         questions or need assistance with anything else, feel free to ask!
 
(ryu) ChatGPS>:

This example uses the alias chatgps instead of Start-Shell. The user and language model engage in a brief conversation about language translation. The user exits the command with the '.exit' shell command and is returned to the PowerShell prompt. The user re-invokes Start-ChatShell through the chatgps alias, and Start-Shell then displays the last message in the conversation so the user can re-engage.

.EXAMPLE
chatgps
 
░█▀▀░█░█░█▀█░▀█▀░█▀▀░█▀█░█▀▀
░█░░░█▀█░█▀█░░█░░█░█░█▀▀░▀▀█
░▀▀▀░▀░▀░▀░▀░░▀░░▀▀▀░▀░░░▀▀▀
 
Welcome to ChatGPS Shell 0.1.0!
 
Tuesday, July 15, 2025 10:42:46 PM
 
 * View configuration at ~/.chatgps/settings.json
 * Enter '.help' for a list of built-in shell commands
 
(ryu) ChatGPS>: .help
 
Shell commands must start with '.'; valid commands are:
 
- .clearhistory
- .exit
- .help
- .history
- .last
- .showconnection
 
(ryu) ChatGPS>: .help

In this example Start-Shell is started using its alias, and this is the first time Start-ChatShell has been invoked in this PowerShell session, so it shows a welcome message. The user enters the '.help' shell command which shows a list of all the valid shell commands. Note that the example text above contains an oddity where the shell commands listed above are prefixed with a '-' -- this is due to the fact that this very documentation is sourced in PowerShell comment help, and apparently a line starts with a '.' this can invalidate the comment help and the command will then have no documentation exposed in the Get-Help command. So the '-' character is not part of the actual command functionality, just a mechanism to work around a limitation in PowerShell's command help implementation. The '-' characters must not be removed from this documentation even though it is not part of the actual functionality unless a new mechanism is used for documentation.

.EXAMPLE
$encryptedBingApiKey = Get-AzKeyVaultSecret -VaultName BingVault -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > Add-ChatPlugin -PluginName Bing -ParameterNames apiKey -ParameterValues $encryptedBingApiKey
PS > Add-ChatPlugin -PluginName TimePlugin
PS > chatgps
(ryu) ChatGPS>: Can you tell me the latest PowerShell version released this year?
 
Received                 Response
--------                 --------
7/19/2025 11:59:43 PM    The latest PowerShell version released this year (2025) is PowerShell 7.5. The General
                         Availability (GA) of PowerShell 7.5 is expected in January or February 2025, and it
                         is built on top of .NET 9.0.301. There is also a preview version 7.6 available recently, but
                         7.5 is the stable release for this year.
 
(ryu) ChatGPS>: When was PowerShell 7.5 released?
 
7/20/2025 12:00:01 AM    PowerShell 7.5 became generally available (GA) in March 2025.
 
(ryu) ChatGPS>: What were its top three notable features?
 
7/20/2025 12:00:34 AM    The top three notable features of PowerShell 7.5 are:
 
                         1. **Integration with Windows Package Manager (winget):** PowerShell 7.5 includes native
                         support for managing packages using winget, allowing for streamlined software
                         installation, upgrade, and management directly from the PowerShell console.
 
                         2. **Improved Cross-Platform Support:** This version enhances compatibility and performance
                         across different operating systems, including  Windows, macOS, and various Linux
                         distributions, providing more consistent behavior and better tooling for cross-platform
                         scripting.
 
                         3. **Enhanced Predictive IntelliSense:** PowerShell 7.5 features advanced predictive
                         IntelliSense capabilities, offering smarter command and parameter suggestions based on
                         context and user history, which improves scripting efficiency and reduces errors.
 
                         If you want, I can provide more details or additional features included in PowerShell 7.5.
 
(ryu) ChatGPS>: can you tell me the command I can use to install it?
 
7/20/2025 12:01:59 AM    To install PowerShell 7.5 using the Windows Package Manager (winget), you can use the
                         following command in an elevated PowerShell or Command Prompt:
 
                         ```powershell
                         winget install --id Microsoft.PowerShell --version 7.5
                         ```
 
                         This command will download and install PowerShell 7.5 on your system. If you want to
                         install the latest available version regardless of the specific version number, you
                         can omit the `--version` parameter:
 
                         ```powershell
                         winget install --id Microsoft.PowerShell
                         ```
 
                         Let me know if you need guidance for installing PowerShell 7.5 on other operating
                         systems.
 
(ryu) ChatGPS>:

Here Start-ChatShell is invoked with the chatgps alias after the Bing web search and Time plugins have been configured for the session. As a result, the subsequent conversation in Start-ChatShell includes web searches and time awareness for model interactions, and the user is able to engage the LLM to find new information as the conversation about PowerShell progresses.

.EXAMPLE
Send-ChatMessage 'Can you show a PowerShell script that enumerates all the PowerShell 7 processes?'
 
Received                 Response
--------                 --------
7/20/2025 6:51:21 AM     ```powershell
                         Get-Process pwsh
                         ```
PS > Start-ChatShell
 
Received                 Response
--------                 --------
7/20/2025 6:51:34 AM     ```powershell
                         Get-Process pwsh
                         ```
 
(ryu) ChatGPS>: can you modify it so that it lists them in order of process creation?

7/20/2025 6:52:30 AM     ```powershell
                         Get-Process pwsh | Sort-Object StartTime
                         ```
 
(ryu) ChatGPS>: Thanks. Can you also add a secondary ordering by memory utilization?
 
7/20/2025 6:52:56 AM     ```powershell
                         Get-Process pwsh | Sort-Object StartTime,
                         @{Expression='WorkingSet'; Descending=$true}
                         ```
 
(ryu) ChatGPS>: .exit
 
PS > Send-ChatMessage 'Can you provide that without any markdown formatting please, just PowerShell code?' | Select-Object -ExpandProperty Response | Out-File  ~/Get-PsInstances.ps1
PS > Get-ChatHistory -CurrentContextOnly
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
7/16/2025 6:51:13 AM     User                  0 Can you show a  PowerShell script that enumerates all the
                                                 PowerShell 7 processes?
7/16/2025 6:51:21 AM     Assistant          7667 ```powershell
                                                 Get-Process pwsh
                                                 ```
7/16/2025 6:52:22 AM     User                  0 can you modify it so that it lists them in order of process
                                                 creation?
7/16/2025 6:52:30 AM     Assistant          7345 ```powershell
                                                 Get-Process pwsh | Sort-Object StartTime
                                                 ```
7/16/2025 6:52:56 AM     User                  0 Thanks. Can you also add a secondary ordering by memory
                                                 utilization?
7/16/2025 6:52:56 AM     Assistant           761 ```powershell
                                                 Get-Process pwsh | Sort-Object StartTime,
                                                 @{Expression='WorkingSet'; Descending=$true}
                                                 ```
7/16/2025 6:54:30 AM     User                  0 Can you provide that without any markdown
                                                 formatting please, just PowerShell code?
7/16/2025 6:54:37 AM     Assistant          7531 Get-Process pwsh | Sort-Object StartTime,
                                                 @{Expression='WorkingSet'; Descending=$true}

This demonstrates that the use of Start-ChatShell and Send-ChatMessage may be interleaved, but the converation history across both is treated as a single continuous conversation when interacting with the language model, and this is reflected in the output of the Get-ChatHistory command, even when CurrenTContextOnly is specified it shows that both commands are part of the chat session's ongoing context.

.LINK
Connect-ChatSession
Send-ChatMessage
Clear-ChatHistory
Add-ChatPlugin
Register-ChatPlugin
#>
function Start-ChatShell {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='chat')]
    param(
        [parameter(position=0)]
        [string] $InitialPrompt,

        [parameter(parametersetname='functiondefinition')]
        [string] $FunctionDefinition,

        [parameter(parametersetname='functionname')]
        [string] $FunctionName,

        [parameter(parametersetname='functionid')]
        [string] $FunctionId,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat = 'None',

        [ScriptBlock] $PromptHint = $null,

        [switch] $HideInitialPrompt,

        [switch] $HideInitialResponse,

        [switch] $HidePrompt,

        [switch] $NoOutput,

        [switch] $RawOutput,

        [switch] $NoWelcome,

        [switch] $ShowWelcome,

        [ScriptBlock] $ReceiveBlock,

        [ScriptBlock] $UserReplyBlock,

        [int32] $MaxReplies = 1,

        [switch] $AllowAgentAccess,

        [switch] $DisallowAgentAccess,

        [switch] $NoAutoConnect,

        [switch] $MessageSound,

        [switch] $AllowInitialReceiveBlock,

        [ValidateSet('Normal', 'Large')]
        [string] $SplashTitle = 'Normal',

        [string] $SoundPath,

        [Modulus.ChatGPS.Models.ChatSession]
        $Session
    )

    begin {

        if ( $PSBoundParameters.Keys.Contains('AllowAgentAccess') -and $PSBoundParameters.Keys.Contains('DisallowAgentAccess')) {
            throw [ArgumentException]::new("AllowAgentAccess and DisallowAgentAccess may not both be set")
        }

        $agentAccessParameter = @{}

        if ( $AllowAgentAccess.IsPresent ) {
            $agentAccessParameter.Add('AllowAgentAccess', $AllowAgentAccess)
        }

        if ( $DisallowAgentAccess.IsPresent ) {
            $agentAccessParameter.Add('DisallowAgentAccess', $DisallowAgentAccess)
        }

        $currentReplies = $MaxReplies

        $targetSession = GetTargetSession $Session

        $sessionArgument = if ( ! $NoAutoConnect.IsPresent ) {
            if ( ! $targetSession ) {
                throw "No current session exists -- please execute Connect-ChatSession and retry"
            }
            @{Session = $targetSession}
        } else {
            @{}
        }

        $function = if ( $FunctionDefinition ) {
            New-ChatFunction $FunctionDefinition
        } elseif ( $FunctionName ) {
            Get-ChatFunction -Name $FunctionName
        } elseif ( $FunctionId ) {
            Get-ChatFunction -Id $FunctionId
        }

        $functionDefinitionParameter = if ( $function ) {
            $parameters = $function | Get-ChatFunction | select-object -expandproperty Parameters

            if ( ! ( $parameters.keys -contains 'input' ) ) {
                throw [ArgumentException]::new("The specified function does not contain the mandatory parameter named 'input'")
            }

            @{FunctionDefinition=$FunctionDefinition}
        } else {
            @{}
        }

        $replState = [ReplState]::new($sessionArgument.Session, 'NaturalLanguage')

        $soundParameters = @{}
        if ( $MessageSound.IsPresent ) { $soundParameters['MessageSound'] = $MessageSound }
        if ( $SoundPath ) { $soundParameters['SoundPath'] = $SoundPath }

        $targetReceiveBlock = @{}

        if ( $ReceiveBlock ) {
            $targetReceiveBlock = @{ReceiveBlock=$ReceiveBlock}
        }

        $initialResponse = $null

        if ( $InitialPrompt ) {
            $initialResponse = Send-ChatMessage $InitialPrompt @sessionArgument @soundParameters

            if ( ! $HideInitialPrompt.IsPresent ) {
                $conversationTitle = "Conversation: '$InitialPrompt'"
                "`n$($conversationTitle)" | write-host -foregroundcolor cyan
                ( '-' * $conversationTitle.Length ) | write-host -foregroundcolor cyan
            }
        } elseif ( $sessionArgument.Session ) {
            $lastMessage = $sessionArgument.Session.CurrentHistory | select -last 1
            $initialResponse = if ( $lastMessage.Role -eq 'assistant' ) {
                $lastMessage.Content |
                  ToResponse -role $lastMessage.Role -Received ([DateTime]::now)
            }
        }

        $inputHintArgument = if ( ! $HidePrompt.IsPresent ) {
            $targetPrompt = if ( $PromptHint ) {
                $PromptHint
            } else {
                { $prefix = $targetSession.Name ? $targetSession.Name : ( $env:USER ? $env:USER : $env:USERNAME ); "($($prefix)) ChatGPS>" }
            }
            @{Prompt=$targetPrompt}
        } else {
            @{}
        }

        $lastResponse = $initialResponse
        $lastInputText = $null

        $initialReceiveBlock = $AllowInitialReceiveBlock.IsPresent ? $targetReceiveBlock : @{}

        $transformedResponse = if ( $initialResponse -and ! $HideInitialResponse.IsPresent ) {
            TransformResponseText -Response $initialResponse -OutputFormat $OutputFormat @initialReceiveBlock | ToResponse -role $initialResponse.Role -AsString:$RawOutput.IsPresent -Received ([DateTime]::now)
        }

        if ( ! $NoOutput.IsPresent ) {
            $transformedResponse
        }

        ShowWelcome $NoWelcome.IsPresent $SplashTitle $ShowWelcome.IsPresent
    }

    process {

        while ( $true ) {
            $inputHintValue = if ( $InputHintArgument.Count -gt 0 ) {
                Invoke-Command -scriptblock $InputHintArgument.Prompt
            }

            $dynamicInputHintArgument = if ( $inputHintValue ) {
                @{Prompt = $inputHintValue}
            } else {
                @{}
            }

            $replyText = if ( $UserReplyBlock -and ( $currentReplies -ne 0 ) -and ( $lastResponse -ne $null ) ) {
                $replyData = GetChatReply -ResponseMessage $lastResponse.Response -ReplyBlock $UserReplyBlock -MaxReplies $currentReplies -UserPrompt $lastInputText

                if ( $replyData ) {
                    if ( $inputHintValue ) {
                        Write-Host "$($InputHintValue): " -nonewline
                        Write-Host $replyData.Reply
                    }
                    $currentReplies = $replyData.nextMax
                    $replyData.Reply
                }
            }

            $inputText = if ( ! $replyText ) {
                if ( $dynamicInputHintArgument.Prompt ) {
                    write-host -foregroundcolor cyan "`n$($dynamicInputHintArgument.Prompt): " -nonewline
                }

                #
                # So there is a serious limitation in PowerShell itself -- see https://github.com/PowerShell/PowerShell/issues/4594.
                # It causes non-determinism in the display of types that are implicitly tables, which is the case of the
                # response objects output in this function. The workaround is to have explicit ps1xml formatting for that type
                # that explicitly specifies a width for every column of the type so that auto-sizing does not happen and bypasses
                # the bug. This would not be noticeable without the Read-Host below, but we want the output of previous iterations
                # to be visible before the user enters the prompt, and at least on the first time through, it's not. Because it
                # seems to correct itself on the second time through, another workaround could be to emit a synthetic / dummy /
                # placeholder response object that will usually not show in the display (but will be in the output).
                #
                Read-Host
            } else {
                $replyText
            }

            $forceChat = $false

            $replCommandResult = if ( $inputText ) {
                InvokeReplCommand $inputText $replState.GetState()
            }

            if ( $replCommandResult ) {
                $replState.Update($replCommandResult.UpdatedReplState)

                if ( $replState.Status -eq [ReplStatus]::Exited ) {
                    break
                } else {
                    $replCommandResult.Result
                    continue
                }
            }

            if ( ! $inputText ) {
                break
            } elseif ( $inputText.Trim().StartsWith('.chat ') ) {
                $keywordLength = '.chat '.Length
                $inputText = $inputText.SubString($keywordLength, $inputText.Length - $keywordLength)
                $forceChat = $true
            }

            $failed = $false

            $result = try {
                Send-ChatMessage $inputText @sessionArgument -OutputFormat $OutputFormat @targetReceiveBlock @soundParameters -RawOutput:$RawOutput.IsPresent @functionDefinitionParameter @agentAccessParameter
                $lastInputText = $inputText
            } catch {
                $failed = $true
                write-error -erroraction continue $_.tostring()
            }

            if ( $failed ) {
                continue
            }

            $lastResponse = $result

            if ( $result ) {
                write-host
                $result
            }
        }
    }

    end {
    }
}
