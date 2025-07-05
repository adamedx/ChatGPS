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
function Remove-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name
    )

    begin {
        $functions = GetFunctionInfo
    }

    process {
        $targetId = if ( $Name ) {
            $functions.GetFunctionByName($Name).Id
        } else {
            $Id
        }

        $functions.RemoveFunction($targetId)
    }

    end {
    }
}

[Function]::RegisterFunctionNameCompleter('Remove-ChatFunction', 'Name')
