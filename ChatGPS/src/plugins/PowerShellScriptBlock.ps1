#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
