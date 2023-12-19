#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Connect-ChatSession'
    'Get-ChatConnection'
    'Get-ChatCurrentVoice'
    'Get-ChatVoiceName'
    'New-ChatVoice'
    'Out-ChatVoice'
    'Send-ChatMessage'
    'Set-ChatCurrentVoice'
    'Start-ChatREPL'
)

export-modulemember -function $commands
