#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

class PowerShellScriptBlock : Modulus.ChatGPS.Plugins.IPowerShellScriptBlock {
    PowerShellScriptBlock([string] $name, [ScriptBlock] $scriptBlock, [string] $description, [string] $outputDescription = $null) {
        $this.Name = $name
        $this.Description = $description
        $this.ScriptBlock = $scriptBlock
        $this.ParameterTable = $this.GetParameterInfo($scriptBlock)
        $this.OutputDescription = if ( $outputDescription ) {
            $outputDescription
        } else {
            "This function returns no output; it only produces side effects"
        }
    }

    [string] $Name
    [string] $Description
    [string] $OutputDescription
    [System.Collections.Generic.Dictionary[string,string]] $ParameterTable

    hidden [ScriptBlock] $ScriptBlock

    [object] InvokeAndReturnAsJson([System.Collections.Generic.Dictionary[string,object]] $parameters)
    {
        return ( . $this.ScriptBlock @parameters )
    }

    hidden [System.Collections.Generic.Dictionary[string,string]] GetParameterInfo([ScriptBlock] $scriptBlock) {
        $result = [System.Collections.Generic.Dictionary[string,string]]::new()

        foreach ( $parameter in $scriptBlock.ast.ParamBlock.parameters ) {
            $result.Add($parameter.name, $parameter.StaticType)
        }

        return $result
    }
}
