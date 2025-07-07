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

function Add-ChatPluginFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [PowerShellKernelPluginBuilder] $Plugin,

        [parameter(position=0, mandatory=$true)]
        [string] $FunctionName,

        [parameter(position=1, mandatory=$true)]
        [ScriptBlock] $ScriptBlock,

        [parameter(position=2)]
        [string] $OutputType = 'System.String',

        [string] $Description,

        [string] $OutputDescription,

        [switch] $NoOutput
    )

    $targetDescription = if ( $Description ) {
        $Description
    } else {
        "This method invokes PowerShell code to perform its function."
    }

    $targetPlugin = if ( $Plugin ) {
        $Plugin
    } else {
        [PowerShellKernelPluginBuilder]::new()
    }

    $targetPlugin.AddMethod($FunctionName, $ScriptBlock, $Description, $OutputType, $OutputDescription)

    if ( ! $NoOutput.IsPresent ) {
        $targetPlugin
    }
}
