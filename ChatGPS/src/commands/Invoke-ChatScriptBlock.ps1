#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

function Invoke-ChatScriptBlock {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [ScriptBlock] $ScriptBlock,

        [parameter(position=1)]
        [HashTable] $ScriptParameters
    )
    $parameterList = [System.Collections.Generic.Dictionary[string,object]]::new()

    if ( $ScriptParameters ) {
        foreach ( $parameterName in $ScriptParameters.Keys ) {
            $parameterList.Add($parameterName, $ScriptParameters[$parameterName])
        }
    }

    $invoker = [ScriptBlockPlugin]::new($ScriptBlock)

    [Modulus.ChatGPS.Plugins.PowerShellPluginBase]::Invoke($invoker, $parameterList)
}
