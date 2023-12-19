#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$SpeakerTypeName = 'Speaker'

$DefaultSpeaker = $null
$CurrentSpeaker = $null

function Test-VoiceSupported {
    $PSVersionTable.Platform -eq 'Win32NT'
}

function GetDefaultSpeaker {
    if ( Test-VoiceSupported ) {
        if ( $Script:DefaultSpeaker -eq $null ) {
            $Script:DefaultSpeaker = NewSpeaker -IsAsync $true
        }

        $Script:DefaultSpeaker
    }
}

function GetCurrentSpeaker {
    if ( Test-VoiceSupported ) {
        if ( ! $Script:CurrentSpeaker ) {
            SetCurrentSpeaker
        }

        $Script:CurrentSpeaker
    }
}

function SetCurrentSpeaker($speaker) {
    if ( Test-VoiceSupported ) {
        if ( $speaker ) {
            $Script:CurrentSpeaker = $speaker
        } else {
            $Script:CurrentSpeaker = GetDefaultSpeaker
        }
    }
}

function NewSpeaker([string] $VoiceName, [bool] $isAsync) {
    if ( Test-VoiceSupported ) {
        $result = NewSpeakerInterface

        $targetVoice = if ( $VoiceName ) {
            GetVoice $VoiceName -FailIfNotFound -SpeakerInterface $result
        }

        if ( $targetVoice ) {
            $result.Voice = $targetVoice
        } else {
            $targetVoice = $result.Voice
        }

        HashTableToObject -TypeName $script:SpeakerTypeName -table @{
            VoiceName = $targetVoice.DataKey.GetStringValue('')
            Speaker = $result
            Synchronous = ! $isAsync
        }
    }
}

function NewSpeakerInterface {
    New-Object -ComObject SAPI.SpVoice.1
}

function GetVoice($VoiceName, [switch] $failIfNotFound, $speakerInterface) {
    $result = if ( Test-VoiceSupported ) {
        $targetInterface = if ( $speakerInterface ) {
            $speakerInterface
        } else {
            (GetCurrentSpeaker).Speaker
        }

        $targetInterface.GetVoices() |
          where  { $VoiceName -eq $null ? $true : $_.DataKey.GetStringValue('') -eq $VoiceName }
    }

    if ( $result ) {
        $result
    } elseif ( $VoiceName -and $failIfNotFound.IsPresent ) {
        throw "Specified voice '$VoiceName' could not be found."
    }
}

function SetCurrentVoice {
    param(
        [parameter(parametersetname='byname', mandatory=$true)]
        $VoiceName,

        [parameter(parametersetname='default', mandatory=$true)]
        [switch] $Default
    )

    if ( Test-VoiceSupported ) {
        if ( $VoiceName -ne $null ) {
            $targetVoice = GetVoice $VoiceName -FailIfNotFound
            SetSpeakerVoice $Script:CurrentSpeaker.Speaker.Voice $targetVoice
        } elseif ( $Default.IsPresent ) {
            $firstVoice = GetVoices | select -first 1
            SetSpeakerVoice $Script:CurrentSpeaker.Speaker.Voice $firstVoice
        }
    }
}

function GetSpeakerVoiceName($speaker) {
    if ( Test-VoiceSupported ) {
        $targetSpeaker = if ( $speaker ) {
            $speaker
        } else {
            GetCurrentSpeaker
        }

        $targetSpeaker.Voice.DataKey.GetStringValue('')
    }
}

function SetSpeakerVoice{
    param(
        [parameter(mandatory=$true)]
        [PSCustomObject] $speaker,

        [parameter(mandatory=$true)]
        [string] $voiceName)

    if ( Test-VoiceSupported ) {
        $targetVoice = GetVoices $voiceName -FailIfNotFound
        $speaker.Spaker.Voice = $targetVoice
    }
}

function GetVoiceParameterCompleter {
    {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        $speaker = (GetDefaultSpeaker)
        if ( $speaker ) {
            $voices = $speaker.speaker.GetVoices()
            if ( $voices ) {
                ( $voices | foreach { "`"$($_.DataKey.GetStringValue(''))`"" } ) -like "*$($wordToComplete)*" | sort-object
            }
        }
    }
}


RegisterTypeData $script:SpeakerTypeName VoiceName Synchronous
