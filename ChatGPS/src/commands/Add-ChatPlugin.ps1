#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Add-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string[]] $PluginName,

        [parameter(position=1)]
        [object[][]] $Parameters,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [string] $SessionName
    )
    begin {
        if ( $Parameters ) {
            if ( $PluginName.Length -ne $Parameters.Length ) {
                throw [ArgumentException]::new("The number of plugins ($($PluginName.Count)) must match the number of parameter arrays $($Parameters)")
            }
        }
    }

    process {
        $targetSession = if ( ! $SessionName ) {
            Get-ChatSession -Current
        } else {
            Get-ChatSession $SessionName
        }

        $pluginIndex = 0

        foreach ( $name in $PluginName ) {
            $parameter = if ( $Parameters ) {
                $Parameters[$pluginIndex++]
            }
            $targetSession.AddPlugin($name, $parameter)
        }
    }

    end {
    }
}

RegisterPluginCompleter Add-ChatPlugin PluginName
RegisterSessionCompleter Add-ChatPlugin SessionName
