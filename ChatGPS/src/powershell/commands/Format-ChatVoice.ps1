#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Format-ChatVoice {
    [cmdletbinding()]
    param (
        [parameter(valuefrompipeline=$true)]
        [string] $Text = $null
    )

    begin {
        $voice = try {
            New-Object -ComObject SAPI.SpVoice.1
        } catch {
        }
    }

    process {
        if ( $voice -and $Text) {
            $voice.Speak($Text) | out-null
        }

        $Text
    }

    end {
    }
}
