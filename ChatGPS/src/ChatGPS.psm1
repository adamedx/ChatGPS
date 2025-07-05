#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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
