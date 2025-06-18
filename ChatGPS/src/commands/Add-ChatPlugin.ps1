#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Add-ChatPlugin {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='noparameters')]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $PluginName,

        [parameter(parametersetname='parameterlist', position=1, mandatory=$true)]
        [string[]] $ParameterNames,

        [parameter(parametersetname='parametertable', position=1, mandatory=$true)]
        [HashTable] $ParameterTable,

        [parameter(parametersetname='parameterlist', position=2, mandatory=$true)]
        [object[]] $ParameterValues,

        [parameter(parametersetname='parameterlist')]
        [parameter(parametersetname='parametertable')]
        [string[]] $UnencryptedParameters,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [string] $SessionName
    )
    begin {
        $parameterInfo = GetParameters $PluginName $ParameterTable $ParameterNames $ParameterValues $UnencryptedParameters
    }

    process {
        $targetSession = if ( ! $SessionName ) {
            Get-ChatSession -Current
        } else {
            Get-ChatSession $SessionName
        }
        $targetSession.AddPlugin($PluginName, $parameterInfo)
    }

    end {
    }
}

RegisterPluginCompleter Add-ChatPlugin PluginName
RegisterSessionCompleter Add-ChatPlugin SessionName
