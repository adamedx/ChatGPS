#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='byname', position=0)]
        [parameter(parametersetname='listavailable', position=0)]
        [string] $PluginName,

        [parameter(parametersetname='bysessionname', mandatory=$true)]
        [string] $SessionName,

        [parameter(parametersetname='bysessionid', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Alias('Id')]
        [string] $SessionId,

        [parameter(parametersetname='listavailable', mandatory=$true)]
        [switch] $ListAvailable
    )

    begin {
        $filter = if ( $PluginName ) {
            { $_.Name -eq $PluginName }
        } else {
            { $true }
        }
    }

    process {
        $targetSession = if ( ! $ListAvailable.IsPresent ) {
            if ( $SessionName ) {
                Get-ChatSession $SessionName
            } elseif ( $SessionId ) {
                Get-ChatSession -Id $SessionId
            } else {
                Get-ChatSession -Current
            }
        }

        $plugins = if ( ! $targetSession ) {
            [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviders()
        } else {
            $targetSession.Plugins
        }

        $plugins | where $filter | sort-object Name
    }

    end {
    }
}

RegisterPluginCompleter Get-ChatPlugin PluginName
RegisterSessionCompleter Get-ChatPlugin SessionName
