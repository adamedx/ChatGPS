#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

function Unregister-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='byname', position=0, mandatory=$true)]
        [string] $Name,

        [parameter(parametersetname='byobject', valuefrompipeline=$true, mandatory=$true)]
        [Modulus.ChatGPS.Plugins.PowerShellPluginProvider] $Plugin
    )

    begin {
    }

    process {
        $targetPluginName = if ( $Name ) {
            $Name
        } else {
            $Plugin.Name
        }

        [Modulus.ChatGPS.Plugins.PowerShellPluginProvider]::UnregisterProvider($targetPluginName)
    }

    end {
    }
}

RegisterPluginCompleter Unregister-ChatPlugin Name $true
