#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function Remove-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [string[]] $PluginName,

        [string] $SessionName
    )
    begin {
        $targetSession = if ( ! $SessionName ) {
            Get-ChatSession -Current
        } else {
            Get-ChatSession $SessionName
        }
    }

    process {
        $targetSession.RemovePlugin($PluginName)
    }

    end {
    }
}

RegisterPluginCompleter Remove-ChatPlugin PluginName
RegisterSessionCompleter Remove-ChatSession SessionName
