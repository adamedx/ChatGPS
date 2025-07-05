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

# This scriptblock is outside of the module, it is dot-sourced
# into the environment of the caller that imported the module
# via ScriptsToProcess in the module manifest. Because of this,
# it can be used to work around the fact that any functions created
# by code hosted within the module are not visible outside of the module.
$__ChatGPS_ModuleParentFunctionBuilder = {
    param(
        [parameter(mandatory=$true)]
        [string] $functionName,

        [parameter(mandatory=$true)]
        [scriptblock] $scriptBlock,

        [boolean] $force = $false
    )

    new-item -path function:\ -name $functionName -Value $scriptBlock -Force:$force
}
