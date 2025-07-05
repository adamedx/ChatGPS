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



function Remove-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', mandatory=$true, position=0)]
        [Alias('Name')]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [switch] $Force
    )

    begin {
    }

    process {
        $nameOrId = if ( $SessionName ) {
            @{Name=$SessionName}
        } else {
            @{Id=$Id}
        }

        $session = Get-ChatSession @nameOrId

        RemoveSession $session $Force.IsPresent
    }

    end {
    }
}

RegisterSessionCompleter Remove-ChatSession SessionName
