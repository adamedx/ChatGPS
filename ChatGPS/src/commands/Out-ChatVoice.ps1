#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Out-ChatVoice {
    [cmdletbinding()]
    param (
        [parameter(valuefrompipeline=$true)]
        [object] $Text = $null,

        [PSCustomObject] $Speaker
    )

    begin {
        $targetSpeaker = if ( Test-VoiceSupported ) {
            if ( $Speaker ) {
                $Speaker
            } else {
                GetCurrentSpeaker
            }
        }
    }

    process {
        if ( $targetSpeaker -and $Text ) {
            $flags = $targetSpeaker.Synchronous ? 0 : 1
            $targetSpeaker.Speaker.Speak($Text, $flags) | out-null
        }

        $Text
    }

    end {
    }
}
