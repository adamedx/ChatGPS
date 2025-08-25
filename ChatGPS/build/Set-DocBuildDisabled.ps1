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

[cmdletbinding(PositionalBinding=$false)]
param(
    [parameter(mandatory=$true)]
    [switch] $Disabled
)

if ( $Disabled.IsPresent ) {
    set-item env:__CHATGPS_SKIP_DOCS_BUILD '1'
} else {
    set-item env:x__CHATGPS_SKIP_DOCS_BUILD '0'
    remove-item env:__CHATGPS_SKIP_DOCS_BUILD
}
