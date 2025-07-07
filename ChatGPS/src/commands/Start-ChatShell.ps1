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

        [switch] $NoEcho,

        [switch] $NoOutput,

        [switch] $RawOutput,

        [switch] $NoWelcome,

        [ScriptBlock] $ReceiveBlock,

        [ScriptBlock] $UserReplyBlock,

        [int32] $MaxReplies = 1,

        [switch] $NoAutoConnect,

        [switch] $MessageSound,

        [switch] $AllowInitialReceiveBlock,

        [string] $SoundPath,

        [Modulus.ChatGPS.Models.ChatSession]
        $Session
    )

    begin {
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
            $lastMessage = $sessionArgument.Session.History | select -last 1
            $initialResponse = if ( $lastMessage.Role -eq 'assistant' ) {
                $lastMessage.Content |
                  ToResponse -role $lastMessage.Role -Received ([DateTime]::now)
            }
        }

        $inputHintArgument = if ( ! $HidePrompt.IsPresent -and ! $NoEcho.IsPresent ) {
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

        $initialReceiveBlock = $AllowInitialReceiveBlock.IsPresent ? $targetReceiveBlock : @{}

        if ( $initialResponse -and ! $HideInitialResponse.IsPresent -and ! $NoOutput.IsPresent ) {
            TransformResponseText -Response $initialResponse -OutputFormat $OutputFormat @initialReceiveBlock | ToResponse -role $initialResponse.Role -AsString:$RawOutput.IsPresent -Received ([DateTime]::now)
        }

        ShowWelcome $NoWelcome.IsPresent
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
                $replyData = GetChatReply -SourceMessage $lastResponse.Response -ReplyBlock $UserReplyBlock -MaxReplies $currentReplies

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
                # So there is a serious defect in PowerShell itself -- see https://github.com/PowerShell/PowerShell/issues/4594.
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
                Send-ChatMessage $inputText @sessionArgument -OutputFormat $OutputFormat @targetReceiveBlock @soundParameters -RawOutput:$RawOutput.IsPresent @functionDefinitionParameter
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
