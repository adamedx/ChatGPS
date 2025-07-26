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
Experimental command that sends output to a text-to-speech engine.

.DESCRIPTION
This command is experimental.

.OUTPUTS
None.

.LINK
Get-ChatCurrentVoice
Get-ChatVoiceName
Set-ChatCurrentVoice
New-ChatVoice
#>
function Out-ChatVoice {
    [cmdletbinding()]
    param (
        [parameter(valuefrompipeline=$true)]
        [object] $Text = $null,

        [switch] $Silent,

        [PSCustomObject] $Voice
    )

    begin {
        $targetVoice = if ( Test-VoiceSupported ) {
            if ( $Voice ) {
                $Voice
            } else {
                GetCurrentSpeaker
            }
        }
    }

    process {
        if ( ( ! $Silent.IsPresent ) -and $targetVoice -and $Text ) {
            $flags = $targetVoice.Synchronous ? 0 : 1
            $targetVoice.Speaker.Speak($Text, $flags) | out-null
        }

        $Text
    }

    end {
    }
}
