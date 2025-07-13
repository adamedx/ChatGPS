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

class PowerShellKernelPluginBuilder  {
    static [string[]] $GenerationFiles = $null

    static PowerShellKernelPluginBuilder()
    {
        [PowerShellKernelPluginBuilder]::GenerationFiles = @(
            "$psscriptroot/GeneratePlugin.ps1"
        )
    }

    static [Modulus.ChatGPS.Plugins.PowerShellScriptBlock] NewPowerShellPluginFunction([string] $methodName, [ScriptBlock] $scriptBlock, [string] $description, [string] $OutputType = 'System.String', [string] $outputDescription = $null) {
        $parameterInfo = [PowerShellKernelPluginBuilder]::GetParameterInfo($scriptBlock)

        $newMethod = [Modulus.ChatGPS.Plugins.PowerShellScriptBlock]::new($methodName, $scriptBlock, $parameterInfo, $description, $OutputType, $outputDescription)

        return $newMethod
    }

    static hidden [System.Collections.Generic.Dictionary[string,string]] GetParameterInfo([ScriptBlock] $scriptBlock) {
        $result = [System.Collections.Generic.Dictionary[string,string]]::new()

        if ( $scriptBlock.ast.ParamBlock -and ( $scriptBlock.ast.ParamBlock | get-member parameters -erroraction ignore ) ) {
            foreach ( $parameter in $scriptBlock.ast.ParamBlock.parameters ) {
                $result.Add($parameter.name, $parameter.StaticType)
            }
        }

        return $result
    }
}
