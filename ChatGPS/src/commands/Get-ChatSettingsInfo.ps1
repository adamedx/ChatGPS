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

<#
.SYNOPSIS
Gets information about configuration settings for the ChatGPS module, including the location of the settings file.

.DESCRIPTION
The ChatGPS module provides a configuration settings mechanism, including a file for specifying setings, that controls default behaviors of module commands, location and credentials required to access language models, plugins that grant models access to local and other user resources, and chat session use of models. The Get-ChatSettingsInfo command provides information about the configuration file location used by ChatGPS at module load to apply settings as well as the value of the applied settings themselves.

Note that setting values returned by this command may not all have been applied successfully due to configuration or other runtime errors for an individual setting; the settings returned by the command do represent the intended settings expressed in the latest configuration file that was applied even if some errors occurred during settings application.

To create the settings file, use the New-ChatSettings command. The file is a JSON text file that can be edited manually using a text editor, though the Save-ChatSessionSetting command offers a convenient way to add session configuration settings to the file without the use of a text editor.

For detailed information about settings, see the New-ChatSettings command documentation.

.OUTPUTS
Information about the last location from which settings were applied, as well as the current settings that were attempted to be applied.

.EXAMPLE
PS > Get-ChatSettingsInfo
 
LastSettingsLocation     DefaultSettingsLocation  Settings
--------------------     -----------------------  --------
~/.chatgps/settings.json ~/.chatgps/settings.json @{generatedDate=; generatedTool=; lastUpdatedDate=7/2/2025 6:01:09 PM...
 
This example shows information about currently applied settings, as well as the current settings themselves. Note that all fields except for DefaultSettingsLocation will be empty if there is no settings file. If there is no LastSettingsLocation, then a new file may be created at the location given by DefaultSettingsLocation; if the module is loaded into a new PowerShell session, or if the Update-ChatSettings command is invoked, the settings applied in that new file will be applied.

.EXAMPLE
PS > edit (Get-ChatSettingsInfo | Select-Object -ExpandProperty DefaultSettingsLocation | Get-Item).FullName

In this example, the DefaultSettingsLocation property of Get-ChatSettingsInfo is used as a command-line argument to the edit command used to edit text files. This shows how the command can be used to edit or create the settings configuration file manually. The approach will work with any editor that accepts a file system path as a command-line argument such as notepad, vim, emacs, vscode, etc.

.EXAMPLE
PS > $settings = Get-ChattSettingsInfo | Select-Object -ExpandProperty Settings
PS > $settings
 
generatedDate   : 7/2/2025 3:04:08 PM -04:00
generatedTool   : ChatGPS New-ChatSettings
lastUpdatedDate : 7/2/2025 6:01:09 PM -04:00
lastUpdatedTool : ChatGPS Save-ChatSettings
defaultProfile  : WinDev
profiles        : @{list=System.Object[]; defaults=}
sessions        : @{list=System.Object[]; defaults=}
models          : @{list=System.Object[]}
customPlugins   : @{list=System.Object[]}

In this example, the Settings property of the output of Get-ChatSettingsInfo command is assigned to a variable named $settings, which is then emitted to the terminal. High level properties of the settings are shown including the tool used to generate the settings file and the last updated time. The details of settings are contained in the collections sessions, models, and customPlugins. Those properties can be expanded by inspecting the $settings variable by dumping properties directly and / or using the Get-Member and Select-Object commands to reveal the specific configuration values.

.LINK
New-ChatSettings
Save-ChatSessionSetting
Update-ChatSettings
#>
function Get-ChatSettingsInfo {
    [cmdletbinding(positionalbinding=$false)]
    param()

    [PSCustomObject] @{
        LastSettingsLocation = (GetLastSettingsPath)
        DefaultSettingsLocation = (GetDefaultSettingsLocation)
        Settings = (GetLastSettings)
    }
}
