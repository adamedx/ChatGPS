#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Connect-ChatSession'
    'Get-ChatCurrentVoice'
    'Get-ChatEncryptedUnicodeKeyCredential'
    'Get-ChatFunction'
    'Get-ChatHistory'
    'Get-ChatSession'
    'Get-ChatSettingsInfo'
    'Get-ChatVoiceName'
    'Invoke-ChatFunction'
    'New-ChatFunction'
    'New-ChatVoice'
    'New-ChatScriptBlock'
    'Out-ChatVoice'
    'Remove-ChatFunction'
    'Remove-ChatSession'
    'Send-ChatMessage'
    'Set-ChatSession'
    'Set-ChatCurrentVoice'
    'Start-ChatREPL'
    'Update-ChatSettings'
)

$aliases = @(
    'chatgps'
    'frun'
    'gss'
    'ncs'
    'sch'
    'scs'
)

export-modulemember -function $commands -alias $aliases
