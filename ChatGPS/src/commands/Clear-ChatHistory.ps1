#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Clear-ChatHistory {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [Switch] $CurrentContextOnly
    )

    begin {
        $targetSession = GetTargetSession $Session
    }

    process {
        $targetSession.ResetHistory($CurrentContextOnly.IsPresent)
    }

    end {
    }
}
