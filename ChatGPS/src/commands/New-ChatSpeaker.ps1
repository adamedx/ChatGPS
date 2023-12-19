#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function New-ChatSpeaker {
    [cmdletbinding()]
    param(
        [string] $VoiceName,
        [switch] $Synchronous
    )

    NewSpeaker -VoiceName $VoiceName -IsAsync ( ! $Synchronous.IsPresent )
}

Register-ArgumentCompleter -CommandName New-ChatSpeaker -ParameterName VoiceName -ScriptBlock (GetVoiceParameterCompleter)
