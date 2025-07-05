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
