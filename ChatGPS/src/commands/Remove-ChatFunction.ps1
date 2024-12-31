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

        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
        $sessionFunctions = GetSessionFunctions $Session
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

[Function]::RegisterFunctionNameCompleter('Remove-ChatFunction', 'Name')
