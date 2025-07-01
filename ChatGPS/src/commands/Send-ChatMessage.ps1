#
# Copyright (c) Adam Edwards
#
# All rights reserved.


<#

From earlier function prompt
Specify FunctionPrompt so that all chat prompts will be processes through the function specified by FunctionPrompt. The function *must* specify the function using the Handlebars syntax with exactly one parameter named 'input'. See the New-ChatFunction command documentation for more details about function definition syntax.

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
