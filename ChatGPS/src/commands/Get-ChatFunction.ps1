#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function Get-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0)]
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
        if ( $Id ) {
            $sessionFunctions.GetFunctionById($Id)
        } elseif ( $Name ) {
            $sessionFunctions.GetFunctionByName($Name)
        } else {
            $sessionFunctions.GetFunctions()
        }
    }

    end {
    }

}
