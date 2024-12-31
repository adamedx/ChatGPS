#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Connect-ChatSession'
    'Get-ChatCurrentVoice'
    'Get-ChatFunction'
    'Get-ChatHistory'
    'Get-ChatSession'
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
