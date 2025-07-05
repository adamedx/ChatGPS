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



function Get-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='byname', position=0)]
        [parameter(parametersetname='listavailable', position=0)]
        [string] $PluginName,

        [parameter(parametersetname='bysessionname', mandatory=$true)]
        [string] $SessionName,

        [parameter(parametersetname='bysessionid', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Alias('Id')]
        [string] $SessionId,

        [parameter(parametersetname='listavailable', mandatory=$true)]
        [switch] $ListAvailable
    )

    begin {
        $filter = if ( $PluginName ) {
            { $_.Name -eq $PluginName }
        } else {
            { $true }
        }
    }

    process {
        $targetSession = if ( ! $ListAvailable.IsPresent ) {
            if ( $SessionName ) {
                Get-ChatSession $SessionName
            } elseif ( $SessionId ) {
                Get-ChatSession -Id $SessionId
            } else {
                Get-ChatSession -Current
            }
        }

        $plugins = if ( ! $targetSession ) {
            [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviders()
        } else {
            $targetSession.Plugins
        }

        $plugins | where $filter | sort-object Name
    }

    end {
    }
}

RegisterPluginCompleter Get-ChatPlugin PluginName
RegisterSessionCompleter Get-ChatPlugin SessionName
