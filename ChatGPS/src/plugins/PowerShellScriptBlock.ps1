#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

class PowerShellScriptBlock {
    PowerShellScriptBlock([string] $name, [ScriptBlock] $scriptBlock, [string] $description, [string] $outputType = 'System.String', [string] $outputDescription = $null) {
        $this.Name = $name
        $this.Description = $description
        $this.ScriptBlock = $scriptBlock.ToString()
        $this.ParameterTable = $this.GetParameterInfo($scriptBlock)
        $this.OutputType = $outputType
        $this.OutputDescription = if ( $outputDescription ) {
            $outputDescription
        } else {
            "This function returns no output; it only produces side effects"
        }
    }

    PowerShellScriptBlock() {}

    [string] $Name
    [string] $Description
    [string] $OutputType
    [string] $OutputDescription
    [System.Collections.Generic.Dictionary[string,string]] $ParameterTable

    [string] $ScriptBlock

    hidden [System.Collections.Generic.Dictionary[string,string]] GetParameterInfo([ScriptBlock] $scriptBlock) {
        $result = [System.Collections.Generic.Dictionary[string,string]]::new()

        if ( $scriptBlock.ast.ParamBlock -and ( $scriptBlock.ast.ParamBlock | get-member parameters -erroraction ignore ) ) {
            foreach ( $parameter in $scriptBlock.ast.ParamBlock.parameters ) {
                $result.Add($parameter.name, $parameter.StaticType)
            }
        }

        return $result
    }
}
