#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function Remove-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name,

        [Modulus.ChatGPS.Models.ChatSession] $Connection
    )

    begin {
        $targetConnection = if ( $Connection ) {
            $Connection
        } else {
            GetCurrentSession $true
        }

        $sessionFunctions = $targetConnection.SessionFunctions
    }

    process {
        $targetId = if ( $Name ) {
            $sessionFunctions.GetFunctionByName($Name).Id
        } else {
            $Id
        }

        $sessionFunctions.RemoveFunction($targetId)
    }

    end {
    }
}
