#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Get-ChatHistory {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [Switch] $CurrentContextOnly
    )

    begin {
        $targetSession = GetTargetSession $Session

        $targetHistory = if ( $CurrentContextOnly.IsPresent ) {
            $targetSession.CurrentHistory
        } else {
            $targetSession.History
        }
    }

    process {
        foreach ( $message in $targetHistory ) {
            if ( $message.Role.ToString() -ne 'system' ) {
                $message
            }
        }
    }

    end {
    }
}
