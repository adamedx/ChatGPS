#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function New-ChatVoice {
    [cmdletbinding()]
    param(
        [string] $VoiceName,
        [switch] $Synchronous
    )

    NewSpeaker -VoiceName $VoiceName -IsAsync ( ! $Synchronous.IsPresent )
}

Register-ArgumentCompleter -CommandName New-ChatVoice -ParameterName VoiceName -ScriptBlock (GetVoiceParameterCompleter)
