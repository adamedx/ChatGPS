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

<#
.SYNOPSIS
Experimental command that obtains the current voice for the chat session.

.DESCRIPTION
This command is experimental.

.OUTPUTS
None.

.LINK
Get-ChatCurrentVoice
Get-ChatVoiceName
Set-ChatCurrentVoice
Out-ChatVoice
#>
function Get-ChatCurrentVoice {
    [cmdletbinding()]
    param()
    GetCurrentSpeaker
}
