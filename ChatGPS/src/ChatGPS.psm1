#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Connect-ChatSession'
    'Get-ChatConnection'
    'Get-ChatCurrentSession'
    'Get-ChatCurrentVoice'
    'Get-ChatFunction'
    'Get-ChatVoiceName'
    'Invoke-ChatFunction'
    'New-ChatFunction'
    'New-ChatVoice'
    'New-ChatScriptBlock'
    'Out-ChatVoice'
    'Remove-ChatFunction'
    'Send-ChatMessage'
    'Set-ChatCurrentVoice'
    'Start-ChatREPL'
)

export-modulemember -function $commands
