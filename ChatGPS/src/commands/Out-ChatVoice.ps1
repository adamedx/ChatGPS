#
# Copyright (c) Adam Edwards
#
# All rights reserved.

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
