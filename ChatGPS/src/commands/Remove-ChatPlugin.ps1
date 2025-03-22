#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Remove-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string[]] $PluginName,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )
    begin {
    }

    process {
        $targetSession = if ( ! $Session ) {
            Get-ChatSession -Current
        } else {
            $Session
        }

        foreach ( $name in $pluginName ) {
            $targetSession.RemovePlugin($name)
        }
    }

    end {
    }
}
