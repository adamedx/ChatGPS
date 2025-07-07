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
Applies the latest configuration settings that are specified in the default configuration file or a specified configuration file.

.DESCRIPTION
The ChatGPS module provides a configuration settings mechanism for user preferences for command behavior as well as for specifying the locations of and credentials for accessing language models through ChatGPS commands, among many other settings. The Update-ChatSetting command performs the same procedure to applyconfiguration settings that is performed when the ChatGPS module is imported, but it uses the latest values from the configuration file (the default configuration file or optionally a specific configuration file).

For more details on configuration settings, see the Save-ChatSessionSetting command documentation.

Note that because configuration settings include the ability to define sessions and plugins among other artifacts, warnings may occur during Update-ChatSettings invocation because the settings in the file may correspond to sessions or plugins that are already defined; the existing defined sessions and plugins will not be impacted and the update for any such conflicting settings will simply be skipped.

.OUTPUTS
None.

.EXAMPLE
PS > Update-ChatSettings

In this example the Update-ChatSettings command was executed with no parameters and encountered no warnings.

.EXAMPLE
PS > Update-ChatSettings
 
WARNING: The settings at location '~/.chatgps/settings.json' are incorrectly formatted. The
following error was encountered reading the data: Exception calling "Deserialize" with "2"
argument(s): "'"' is invalid after a value. Expected either ',', '}', or ']'. Path: $.sessi
ons.list[0] | LineNumber: 19 | BytePositionInLine: 8."

In this example, Update-ChatSettings encountered an error in the configuration file, likely due to a mistake in manual editing. As a result, the file is essentially corrupt and updated settings from the file will not be applied. Editing the file to address the syntax error and then re-invoking the command will allow the latest settings in the file to be applied without error.

.EXAMPLE
PS > Get-ChatSettingsInfo
 
LastSettingsLocation     DefaultSettingsLocation  Settings
--------------------     -----------------------  --------
~/.chatgps/settings.json ~/.chatgps/settings.json @{generatedDate=; generatedTool=; lastUpdatedDate=7/2/2025 6:01:09...
 
PS > Update-ChatSettingsInfo -SettingsFilePath ~/.chatgps/settings.bak.json
 
PS > Get-ChatSettingsInfo
 
LastSettingsLocation         DefaultSettingsLocation  Settings
--------------------         -----------------------  --------
~/.chatgps/settings.bak.json ~/.chatgps/settings.json @{generatedDate=; generatedTool=; lastUpdated=4/13/2025 12:15:23...

In this example the SettingsFilePath parameter of Update-ChatSettings is used to apply settings from a different configuration file. Invocations of the Get-ChatSettingsInfo command before and after the use of Update-ChatSettings show that the LastSettingsLocation has changed from being the same as the default setting location of ~/.chatgps/settings.json to the path specified as the SettingsFilePath. Use of Get-ChatSession in a similar before-and-after fashion can show any new sessions that may have been created as a result of updating the settings.


.LINK
New-ChatSettings
Save-ChatSessionSetting
Get-ChatSession
#>
function Update-ChatSettings {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)] [string] $SettingsFilePath = $null
    )
    InitializeCurrentSettings $SettingsFilePath
}
