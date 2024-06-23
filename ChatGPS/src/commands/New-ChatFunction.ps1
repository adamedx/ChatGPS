#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function New-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, ValueFromPipelineByPropertyName=$true)]
        [string] $Definition,
        [parameter(position=1, ValueFromPipelineByPropertyName=$true)]
        [string] $Name,
        [switch] $Force,
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
        $parameters = [Function]::GetParametersFromDefinition($Definition)

        $function = [Modulus.ChatGPS.Models.Function]::new($Name, $parameters, $Definition)
        $sessionFunctions.AddFunction($function, $Force.IsPresent)

        $function
    }

    end {
    }

}
