#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Send-ChatMessage {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true, valuefrompipeline=$true)]
        [string] $Message,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat,

        [ScriptBlock] $ResponseBlock,

        [ScriptBlock] $ReplyBlock,

        [int32] $MaxReplies = 1,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection,

        [switch] $RawOutput,

        [switch] $NoOutput,

        [switch] $ForceChat
    )

    begin {
        $currentMessage = $message
        $currentReplies = $MaxReplies

        $formatParameters = GetPassthroughChatParams -AllParameters $PSBoundParameters
    }

    process {

        while ( $currentMessage ) {

            $targetConnection = if ( $Connection ) {
                $Connection
            } else {
                GetCurrentSession $true
            }

            $response = SendMessage $targetConnection $currentMessage $ForceChat.IsPresent

            $responseInfo = $targetConnection.History | select -last 1

            if ( ! $NoOutput.IsPresent ) {
                $responseObject = $response | ToResponse -role $responseInfo.Role.Label -Received ([DateTime]::now)
                $transformed = $responseObject | TransformResponseText @formatParameters
                if ( ! $RawOutput.IsPresent ) {
                    $transformed | ToResponse -role $responseObject.Role -Received $responseObject.Received
                } else {
                    $transformed
                }
            }

            $replyData = GetChatReply -SourceMessage $response -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

            $currentMessage = if ( $replyData ) {
                $currentReplies = $replyData.NextMax
                $replyData.Reply
            }
        }
    }

    end {
    }
}
