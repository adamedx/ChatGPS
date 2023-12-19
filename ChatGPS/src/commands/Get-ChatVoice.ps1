#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Get-ChatVoice {
    [cmdletbinding()]
    param (
        [parameter(valuefrompipeline=$true)]
        [string] $VoiceName = $null
    )

    begin {
    }

    process {
        GetVoice $VoiceName -FailIfNotFound | foreach {
            $_.DataKey.GetStringValue('')
        }
    }

    end {
    }
}

Register-ArgumentCompleter -CommandName Get-ChatVoice -ParameterName VoiceName -ScriptBlock (GetVoiceParameterCompleter)
