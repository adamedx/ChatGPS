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


$colorEscapeChar = "$([char]0x1b)"
$colorEndChar = "$($colorEscapeChar)[0m"

# Note that this function is invoked in the format ps1xml,
# and those scriptblocks are outside the scope of this module
# where this function is defined. As a result, a scriptblock
# of the module must
function HighlightText([string]$text, [int] $colorValue) {
    if ( $global:host.ui.SupportsVirtualTerminal -and $text ) {
        $background = 40 + $colorValue
        "$($script:colorEscapeChar)[" + "$($background.ToString())m" + $text + $script:colorEndChar
    } else {
        $text
    }
}

