#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

function New-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $Name,

        [parameter(position=1)]
        [string] $Description,

        [parameter(parametersetname='existingplugin', valuefrompipeline=$true, mandatory=$true)]
        [PowerShellKernelPluginBuilder] $Plugin,

        [parameter(parametersetname='newplugin', mandatory=$true)]
        [System.Collections.Generic.Dictionary[string,PowerShellScriptBlock]] $Scripts
    )

    $targetScripts = if ( $Plugin ) {
        $Plugin.Scripts
    } else {
        $Scripts
    }

    $newPlugin = [Modulus.ChatGPS.Plugins.PowerShellPlugin]::new($Name, $Description, $targetScripts, [PowerShellKernelPluginBuilder]::GenerationFiles[0])

    [Modulus.ChatGPS.Plugins.PluginProvider]::NewProvider($newplugin)
}
