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

<#
.SYNOPSIS
Configures a session to use the specified chat plugin to execute code locally during language model interactions.

.DESCRIPTION
Add-ChatPlugin adds the specified chat plugin to a session so that if the session is also enabled for agent access, language model interactions with ChatGPS commands for that session can invoke code on the local system. This allows language models to process information about the local system or other resources to which the user has access. Plugins also allow the local system to make changes to the local system or other resources accessible to the user, effectively allowing the model to act as an "agent" performing tasks on behalf of the user. Chat plugins are enabled for a given session, and by default sessions have no plugins, so chat session interactions with the model have no side effects and do not send information to the model beyond what is explicitly sent by the user to the model through ChatGPS commands.

Adding a plugin to the session does not automatically enable its access during language model interactions -- the session's AllowAgentAccess property must also be configured; this can be accomplished through the Set-ChatAgentAccess command or at session creation time through the Connect-ChatSession command or settings configuration. There is no limit on the number of plugins that may be added to a session by the Add-ChatPlugin command -- it is expected that the capabilities of more than one plugin may be needed for a given scenario, though in practice there is a language model-dependent threshold of plugin count where the model's ability to choose plugins degrades leading to ineffective and undesirable behaviors.

Available plugins that can be added by the Add-ChatPlugin command may be enumerated by invoking the comman Get-ChatPlugin -ListAvailable. By default, Add-ChatPlugin adds the the plugin to the current session, though an alternate session can be specified through the SessionName parameter.

Plugins added to the session by Add-ChatPlugin may also be removed using the Remove-ChatPlugin command; this removes their functionality from the session.

Many plugins can simply be added to the session by specifying only the plugin name to Add-ChatPlugin, but other plugins require parameters when they are added, such as those that utilize particular credentials to access resources on behalf of the user. When a parameter is required but not specified, Add-ChatPlugin will fail with information identifying the parameter that must be specified.

Note that plugins may also be added to a session at session creation time through the Connect-ChatSession command or through settings configuration.

In addition to the built-in plugins available in the default configuration of ChatGPS, Add-ChatPlugin can also add custom plugins that you define to the session. For more details on custom plugins, see the documentation for the Register-ChatPlugin command.

.PARAMETER Name
The name of the chat plugin to retrieve. When ListAvailable is not specified, the command returns a plugin with this name in the current session. If the ListAvailable flag is specified, then registered plugins that contain the specified value of this parameter in the name are returned, allowing the user to find available plugins related to a particular function specified by Name.

.PARAMETER SessionName
The name property of an existing session for which plugins added to that session should be retrieved. If neither this nor the Session parameter are specified then plugins are enumerated from the current session.

.PARAMETER ParameterNames
For plugins that utilize or even require parameters, the ParameterNames and ParameterValues parameters may be used to specify the plugin parameters. ParameterNames is an array; each element is the name of one of the parameters to be specified for the plugin. For each element of ParameterNames, there must be a corresponding value specified as an element for ParameterValues; elements at the same index in each of these arrays can be thought of as key-value pairs that specify the value (from ParameterValues) for a given parameter (named by the same index in ParameterNames). An alternative to the ParameterNames and ParameterValues options is to use the ParameterTable parameter where parameter names and values can be specified as a single HashTable parameter. The ParameterNames and ParameterValues approach is often easier or more intuitive to specify when the number of parameters is low and parameters themselves are simple (strings or integers rather than complex types).

.PARAMETER ParameterValues
For plugins that utilize or even require parameters, the ParameterNames and ParameterValues parameters may be used to specify the plugin parameters. ParameterNames is an array; each element is the name of one of the parameters to be specified for the plugin. For each element of ParameterNames, there must be a corresponding value specified as an element for ParameterValues; elements at the same index in each of these arrays can be thought of as key-value pairs that specify the value (from ParameterValues) for a given parameter (named by the same index in ParameterNames). An alternative to the ParameterNames and ParameterValues options is to use the ParameterTable parameter where parameter names and values can be specified as a single HashTable parameter. The ParameterNames and ParameterValues approach is often easier or more intuitive to specify when the number of parameters is low and parameters themselves are simple (strings or integers rather than complex types).

.PARAMETER ParameterTable
For plugins that utilize or even require parameters, ParameterTable is a mechanism for specifying the parameters. ParameterTable is a HashTable, and the keys of the table are the parameter names being specified, and the values of those keys are the values for those parameters. To identify parameters available to or required for a plugin, invoke the Get-ChatPlugin command with the -ListAvailable option. An alternative to the ParameterTable option is to use the ParameterNames and ParameterValues parameters.

.PARAMETER UnencryptedParameters
This parameter is an array of parameter names that are a subset of the parameter names specified through either the ParameterNames or ParameterTable parameter. By including a parameter name as an element of UnencryptedParameters, Add-ChatPlugin will assume that if such parameters are defined as encrypted by the plugin, the command will not treat the values specified through ParameterValues or ParameterTable as already decrypted, i.e. plain text. This approach must only be used with non-production values as the plugin's definition of the parameter as encrypted implies that disclosure of the value is a security breach. Use of the unencrypted version of the value is suitable for pure test environments and values that pose no threat if they are actually leaked or obtained by an adversary.

.PARAMETER SessionName
The name of the chat session to which to add the plugin. By default when this parameter is not specified, the chat plugin will be added to the current session.

.OUTPUTS
None.

.EXAMPLE
Add-ChatPlugin TimePlugin
 
PS > Send-ChatMessage 'What is the date today?'
 
Received                 Response
--------                 --------
7/13/2025 10:10:13 AM    Today's date is July 13, 2025.
 
PS > Get-Date
 
Sunday, July 13, 2025 3:31:06 AM

In this example, the time plugin is added to the current session, and because the AllowAgentAccess property is configured to allow plugin execution, the response to the question about the current date from Send-ChatMessage accurately reflects the time on the current system as shown by the output of the Get-Date command.

.EXAMPLE
Add-ChatPlugin TimePlugin
 
Send-ChatMessage 'What is the date today?'
 
Received                 Response
--------                 --------
7/13/2025 10:09:24 AM    Today's date is October 5, 2023.
 
PS > Get-Date
 
Sunday, July 13, 2025 3:31:06 AM

PS > Set-ChatAgentAccess -Allowed

Send-ChatMessage 'What is the date today?'

Received                 Response
--------                 --------
7/13/2025 10:10:13 AM    Today's date is July 13, 2025.

In this example, the time plugin is added, but the subsequent response from Send-ChatMessage to the question about the current date yields a dramatically different date in the past that reflects the language model's training time frame rather than the current date as shown by the Get-Date command. The plugin's inactivity is due to the current session's AllowAgentAccess property not being set to true. Use of the Set-ChatAgentAccess command to enable agent access allows the Send-ChatMessage invocation to be retried, and the response then reflects the current date as seen by the local system and surfaced in Get-Date.

.EXAMPLE
$encryptedBingApiKey = Get-AzKeyVaultSecret -VaultName BingVault -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > Add-ChatPlugin -PluginName Bing -ParameterNames apiKey -ParameterValues $encryptedBingApiKey
PS > Add-ChatPlugin -PluginName TimePlugin
PS > Send-ChatMessage 'Can you give a very brief synopsis of three of the latest new features released for PowerShell? Please describe specific features, not just the releases. Please also indicate the approximate dates they were released.'

Received                 Response
--------                 --------
7/19/2025 11:15:53 PM    Here are three of the latest new features released for PowerShell in
                         the last three months:

                         1. PSDirectToVariable (experimental feature) - This new feature allows
                         direct assignment of output to variables, which can enhance
                         scripting convenience and efficiency. [Release date: recent within last 3
                         months, exact date not specified]

                         2. PSNativeWindowsTildeExpansion (experimental feature) - A feature
                         that improves path handling by expanding tilde (~) paths natively on
                         Windows environments. This helps in better path resolution in scripts.
                         [Release date: recent within last 3 months, exact date not specified]

                         3. PSSerializeJSONLongEnumAsNumber (experimental feature) - This feature
                         provides better serialization options for JSON, specifically handling long
                         enums as numbers during serialization, improving compatibility and performance in data
                         interchange. [Release date: recent within last 3 months, exact date not specified]

                         These come with bug fixes and various improvements to the PowerShell
                         environment as part of the update released recently. The specific
                         release date for these features is around July 2025.

                         If you want details on specific release notes or dates for minor updates,
                         I can assist further.

This example shows how to specify encrypted parameters to chat plugins using the Bing web search plugin to demonstrate. In the case of Bing, encryption is required for the 'apiKey' parameter. The value of the parameter is obtained from a secure Azure KeyVault resource, and then encrypted with Get-ChatEncryptedUnicodeKeyCredential such that ChatGPS commands can decrypt it at the time the plugin needs to use the key to access Bing.

The Bing plugin, along with the Time plugin are used when Send-ChatMessage is invoked to find information about the latest releases of PowerShell.

.EXAMPLE
$encryptedGoogleApiKey = Get-AzKeyVaultSecret -VaultName GoogleApiVault -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > $googleSearchEngineId = (Get-Content $env:CONFIG_ROOT/SearchEngineId.txt | out-string).Trim()
PS > Add-ChatPlugin -PluginName Google -ParameterNames apiKey, searchEngineId -ParameterValues $encryptedGoogleApiKey, $googleSearchEngineId

This example for the Google plugin is similar to that above, except that more than one parameter is specified for the plugin, in this case both a 'apiKey' parameter along with a 'searchEngineId'. Note that the indices of elements for ParameterNames and ParameterValues must correspond to match the correct parameter value with the correct parameter.

.EXAMPLE
$encryptedGoogleApiKey = Get-AzKeyVaultSecret -VaultName GoogleApiVault -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > $googleSearchEngineId = (Get-Content $env:CONFIG_ROOT/SearchEngineId.txt | out-string).Trim()
PS > Add-ChatPlugin -PluginName Google -ParameterTable @{apiKey=$encryptedGoogleApiKey;searchEngineId=$googleSearchEngineId}

This is equivalent to the previous example, however instead of using ParameterNames and ParameterValues to specify the parameters, the ParameterTable parameter is used to specify a single hash table that contains the key-value pairs for parameter names and values.

.LINK
Set-ChatAgentAccess
Remove-ChatPlugin
Register-ChatPlugin
Connect-ChatSession
Save-ChatSessionSetting
#>
function Add-ChatPlugin {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='noparameters')]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $Name,

        [parameter(parametersetname='parameterlist', position=1, mandatory=$true)]
        [string[]] $ParameterNames,

        [parameter(parametersetname='parameterlist', position=2, mandatory=$true)]
        [object[]] $ParameterValues,

        [parameter(parametersetname='parametertable', position=1, mandatory=$true)]
        [HashTable] $ParameterTable,

        [parameter(parametersetname='parameterlist')]
        [parameter(parametersetname='parametertable')]
        [string[]] $UnencryptedParameters,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [string] $SessionName
    )
    begin {
        $parameterInfo = GetPluginParameterInfo $Name $ParameterTable $ParameterNames $ParameterValues $UnencryptedParameters
    }

    process {
        $targetSession = if ( ! $SessionName ) {
            Get-ChatSession -Current
        } else {
            Get-ChatSession $SessionName
        }
        $targetSession.AddPlugin($Name, $parameterInfo)
    }

    end {
    }
}

RegisterPluginCompleter Add-ChatPlugin Name
RegisterSessionCompleter Add-ChatPlugin SessionName
RegisterPluginParameterNameCompleter Add-ChatPlugin ParameterNames
RegisterPluginParameterNameCompleter Add-ChatPlugin UnencryptedParameters
