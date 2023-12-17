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

        [switch] $NoOutput,

        [switch] $ForceChat
    )

    $currentMessage = $message
    $currentReplies = $MaxReplies

    $formatParameters = GetPassthroughChatParams -AllParameters $PSBoundParameters

    while ( $currentMessage ) {

        $targetConnection = if ( $Connection ) {
            $Connection
        } else {
            GetCurrentSession $true
        }

        $response = SendMessage $targetConnection $currentMessage $ForceChat.IsPresent

        if ( ! $NoOutput.IsPresent ) {
            $response | FormatOutput @formatParameters
        }

        $replyData = GetChatReply -SourceMessage $response -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

        $currentMessage = if ( $replyData ) {
            $currentReplies = $replyData.NextMax
            $replyData.Reply
        }
    }
}
