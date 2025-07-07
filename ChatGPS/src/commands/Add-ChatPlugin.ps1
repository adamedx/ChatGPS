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

function Add-ChatPlugin {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='noparameters')]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $PluginName,

        [parameter(parametersetname='parameterlist', position=1, mandatory=$true)]
        [string[]] $ParameterNames,

        [parameter(parametersetname='parametertable', position=1, mandatory=$true)]
        [HashTable] $ParameterTable,

        [parameter(parametersetname='parameterlist', position=2, mandatory=$true)]
        [object[]] $ParameterValues,

        [parameter(parametersetname='parameterlist')]
        [parameter(parametersetname='parametertable')]
        [string[]] $UnencryptedParameters,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [string] $SessionName
    )
    begin {
        $parameterInfo = GetPluginParameterInfo $PluginName $ParameterTable $ParameterNames $ParameterValues $UnencryptedParameters
    }

    process {
        $targetSession = if ( ! $SessionName ) {
            Get-ChatSession -Current
        } else {
            Get-ChatSession $SessionName
        }
        $targetSession.AddPlugin($PluginName, $parameterInfo)
    }

    end {
    }
}

RegisterPluginCompleter Add-ChatPlugin PluginName
RegisterSessionCompleter Add-ChatPlugin SessionName
RegisterPluginParameterNameCompleter Add-ChatPlugin ParameterNames
RegisterPluginParameterNameCompleter Add-ChatPlugin UnencryptedParameters
