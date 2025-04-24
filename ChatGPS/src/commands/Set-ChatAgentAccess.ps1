#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Set-ChatAgentAccess {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(mandatory=$true)]
        [switch] $Allowed,

        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
    }

    process {
        $targetSession = if ( $Session ) {
            $Session
        } else {
            Get-ChatSession -Current
        }

        $targetSession.AllowAgentAccess = $Allowed.IsPresent
    }

    end {
    }
}
