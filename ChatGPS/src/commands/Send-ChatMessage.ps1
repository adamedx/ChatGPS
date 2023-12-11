#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Send-ChatMessage {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true, valuefrompipeline=$true)]
        [string] $Message,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection,

        [switch] $ForceChat
    )

    $targetConnection = if ( $Connection ) {
        $Connection
    } else {
        GetCurrentSession $true
    }

    SendMessage $targetConnection $Message $ForceChat.IsPresent
}
