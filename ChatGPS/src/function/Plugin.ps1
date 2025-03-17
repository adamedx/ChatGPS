#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

class ScriptBlockPlugin : Modulus.ChatGPS.Plugins.PowerShellPluginBase {
    [ScriptBlock] $scriptBlock = $null

    ScriptBlockPlugin([ScriptBlock] $scriptBlock) {
        $this.scriptBlock = $scriptBlock
    }

    [object] Invoke([System.Collections.Generic.Dictionary[string,object]] $parameters) {
        $parameterList = @{}

        foreach ( $parameterName in $parameters.keys ) {
            $parameterList.Add($parameterName, $parameters[$parameterName])
        }

        $result = ( . $this.scriptBlock @parameterList )

        return $result
    }
}
