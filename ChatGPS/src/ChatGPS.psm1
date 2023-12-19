#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Connect-ChatSession'
    'Get-ChatConnection'
    'Get-ChatCurrentSpeaker'
    'Get-ChatVoice'
    'New-ChatSpeaker'
    'Out-ChatVoice'
    'Send-ChatMessage'
    'Set-ChatCurrentSpeaker'
    'Start-ChatREPL'
)

export-modulemember -function $commands
