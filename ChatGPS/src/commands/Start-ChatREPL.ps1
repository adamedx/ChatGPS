#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Start-ChatREPL {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [string] $InitialPrompt,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat = 'None',

        [parameter(valuefrompipeline=$true)]
        $Reply,

        [ScriptBlock] $InputHint = { $userName = $env:USER ? $env:USER : $env:USERNAME; "($($userName)) ChatGPS>" },

        [switch] $HideInitialPrompt,

        [switch] $HideInitialResponse,

        [switch] $HideInputHint,

        [switch] $NoEcho,

        [switch] $NoOutput,

        [switch] $RawOutput,

        [ScriptBlock] $ReceiveBlock,

        [ScriptBlock] $ReplyBlock,

        [int32] $MaxReplies = 1,

        [switch] $NoAutoConnect,

        [switch] $MessageSound,

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

        $inputHintArgument = if ( ! $HideInputHint.IsPresent -and ! $NoEcho.IsPresent ) {
            @{Prompt=$InputHint}
        } else {
            @{}
        }

        $lastResponse = $initialResponse

        if ( $initialResponse -and ! $HideInitialResponse.IsPresent -and ! $NoOutput.IsPresent ) {
            TransformResponseText -Response $initialResponse -OutputFormat $OutputFormat @targetReceiveBlock | ToResponse -role $initialResponse.Role -AsString:$RawOutput.IsPresent -Received ([DateTime]::now)
        }
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

            $replyText = if ( $ReplyBlock -and ( $currentReplies -ne 0 ) ) {
                $replyData = GetChatReply -SourceMessage $lastResponse.Response -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

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

            $result = Send-ChatMessage $inputText -ForceChat:$forceChat @sessionArgument -OutputFormat $OutputFormat @targetReceiveBlock @soundParameters -RawOutput:$RawOutput.IsPresent

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
