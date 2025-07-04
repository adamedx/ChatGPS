#
# Copyright (c) Adam Edwards
#
# All rights reserved.

. (join-path $psscriptroot ChatGPS.ps1)

$commands = @(
    'Add-ChatPlugin'
    'Add-ChatPluginFunction'
    'Build-ChatCode'
    'Clear-ChatHistory'
    'Connect-ChatSession'
    'Get-ChatCurrentVoice'
    'Get-ChatEncryptedUnicodeKeyCredential'
    'Get-ChatFunction'
    'Get-ChatHistory'
    'Get-ChatPlugin'
    'Get-ChatSession'
    'Get-ChatSettingsInfo'
    'Get-ChatVoiceName'
    'Invoke-ChatScriptBlock'
    'Invoke-ChatFunction'
    'New-ChatFunction'
    'New-ChatPlugin'
    'New-ChatScriptBlock'
    'New-ChatSettings'
    'New-ChatVoice'
    'Out-ChatVoice'
    'Register-ChatPlugin'
    'Remove-ChatFunction'
    'Remove-ChatPlugin'
    'Remove-ChatSession'
    'Save-ChatSessionSetting'
    'Select-ChatSession'
    'Send-ChatMessage'
    'Set-ChatAgentAccess'
    'Set-ChatCurrentVoice'
    'Start-ChatShell'
    'Unregister-ChatPlugin'
    'Update-ChatSettings'
)

$aliases = @(
    'chatgps'
    'frun'
    'Generate-ChatCode'
    'gss'
    'ncs'
    'sch'
    'scs',
    'Start-ChatRepl'
)

export-modulemember -function $commands -alias $aliases
