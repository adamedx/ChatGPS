#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function Invoke-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name,

        [parameter(parametersetname='name', position=1)]
        [parameter(parametersetname='id')]
        [object] $Parameters = $null,

        [Modulus.ChatGPS.Models.ChatSession] $Connection
    )

    begin {
        $targetConnection = if ( $Connection ) {
            $Connection
        } else {
            GetCurrentSession $true
        }

        $sessionFunctions = $targetConnection.SessionFunctions

        $parameterValues = [System.Collections.Generic.Dictionary[string,object]]::new()

        $hasOrderedParameters = $Parameters -ne $null -and ! ( $Parameters -is [HashTable] )

        if ( $Parameters -is [HashTable] ) {
            foreach ( $parameterName in $Parameters.Keys ) {
                $parameterValues.Add($parameterName, $Parameters[$parameterName])
            }
        }
    }

    process {
        $function = if ( $Id ) {
            $sessionFunctions.GetFunctionById($Id)
        } else {
            $sessionFunctions.GetFunctionByName($Name)
        }

        $targetParameters = if ( ! $hasOrderedParameters ) {
            $parameterValues
        } else {
            $boundParameters = [System.Collections.Generic.Dictionary[string,object]]::new()

            $orderedParameterNames = [Function]::GetParametersFromDefinition($function.Definition)

            $parameterIndex = 0

            foreach ( $parameterValue in $Parameters ) {
                if ( $parameterIndex -ge $orderedParameterNames.Count ) {
                    throw [ArgumentException]::new("The function with identifier $($function.Id) and name '$($function.Name)' only has $($orderedParameterNames.Count) parameters but $($parameterIndex + 1) parameters were specified")
                }
                $boundParameters.Add($orderedParameterNames[$parameterIndex], $parameterValue)
                $parameterIndex++
            }

            $boundParameters
        }

        $result = $function.InvokeFunctionAsync($targetConnection.AIService, $targetParameters)

        $result.Result
    }

    end {
    }

}
