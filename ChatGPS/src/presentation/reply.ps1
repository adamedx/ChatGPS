#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function GetChatReply {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [string] $SourceMessage,
        [ScriptBlock] $ReplyBlock,
        [int32] $MaxReplies
    )

    $nextMax = $MaxReplies
    $replyParams = @{}

    if ( $ReplyBlock -and $MaxReplies -ne 0 ) {
        $reply = Invoke-Command -ScriptBlock $ReplyBlock -ArgumentList $SourceMessage
        if ( $reply ) {

            if ( $nextMax -ne -1 ) {
                $nextMax = $nextMax - 1
            }
        }

        [PSCustomObject] @{
            Reply = $reply
            NextMax = $nextMax
        }
    }
}
