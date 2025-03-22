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
        [object[][]] $PluginParameters,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )
    begin {
        if ( $PluginParameters ) {
            if ( $PluginName.Length -ne $PluginParameters.Length ) {
                throw [ArgumentException]::new("The number of plugins ($($PluginName.Count)) must match the number of parameter arrays $($PluginParameters)")
            }
        }
    }

    process {
        $targetSession = if ( ! $Session ) {
            Get-ChatSession -Current
        } else {
            $Session
        }

        $pluginIndex = 0

        foreach ( $name in $pluginName ) {
            $parameter = if ( $PluginParameters ) {
                $PluginParameters[$pluginIndex++]
            }
            $targetSession.AddPlugin($name, $parameter)
        }
    }

    end {
    }
}
