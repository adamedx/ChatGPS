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
Registers a new user created chat plugin using PowerShell script code and makes it available for use with sessions through the Add-ChatPlugin command.

.DESCRIPTION
Register-ChatPlugin allows users to define new chat plugins and make them available for use in chat sessions. ChatGPS provides several built-in plugins from Semantic Kernel, and Register-ChatPlugin enables you to define any number of custom plugins with arbitrary functionality. Plugins registed by Register-ChatPlugin will be returned by an invocatio of the Get-ChatPlugin -ListAvailable command along with the built-in plugins. For more details on chat plugins and the features they provide, see the documentation for Add-ChatPlugin.

Chat plugins are defined as a collection of one or more functions, and to create a plugin with Register-ChatPlugin, you simply supply a collection of PowerShell script blocks as the function collection. Register-ChatPlugin can accept any number of plugin functions created by the Add-ChatPluginFunction through the pipeline as a way to specify the collection. A hash table containing all of the plugin's functions as script blocks may also be directly specified as the plugin collection.

.PARAMETER Name
The name under which chat plugin should be registered. This name must be unique, i.e. there must be no existing plugin registered by the value assigned to Name. When adding this plugin to a session using the Add-ChatPlugin command, the name parameter is given to specify the registered plugin to add to the session. Note that the plugin's LLM integration may use the name to help the LLM understand the plugin's purpose so that it can decide when to use it, so while an arbitrary plugin will be accepted, the plugin will be most likely to be invoked correctly if the name reflects its purpose.

.PARAMETER Description
An optional detailed description of the plugin's purpose. The description is used by the language model to decide when to use the plugin, and helps differentiate it from other plugins that may seem to to have similar capabilities when only the plugin's name is considered.

.PARAMETER Plugin


.PARAMETER Scripts

.OUTPUTS
When ListAvailable is not specified, the command returns all plugins added to the specified session, or just the specific plugin identified by the Name parameter. When ListAvailable is specified, the command returns all registered chat plugins, i.e. plugins availalble to be added to any session, and if Name is specified the list is filtered to anything that contains Name.

.EXAMPLE
PS > Get-ChatPlugin
 
Name                     Description                              Parameters
----                     -----------                              ----------
Bing                     Enables access to search the web using   apiKey
                         the following search engine source: Bing
FileIOPlugin             Enables read and write access to the
                         local file system.
system_powershell_agent  Uses powershell code to interact with
                         the operating system
TimePlugin               Uses the local computer to obtain the
                         current time.

In this example, Get-ChatPlugin with no arguments lists the plugins currently added to the session.


This invocation set the current session to a session named 'CodingSession'. Subsequent commands that interact with langauge models will use this session unless an override is specified for that particular command.

.EXAMPLE
PS > Get-ChatPlugin -ListAvailable
 
Name                     Desciption                               Parameters
----                     ----------                               ----------
Bing                     Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                         the following search engine source: Bing
FileIOPlugin             Enables read and write access to the
                         local file system.
Google                   Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                         the following search engine source:
                         Google
HttpPlugin               Enables the local computer to access
                         local and remote resources via http
                         protocol requests.
msgraph_agent            Accesses the Microsoft Graph API
                         service to obtain information from and
                         about the service.
SearchUrlPlugin          Computes the search url for popular
                         websites.
system_powershell_agent  Uses powershell code to interact with
                         the operating system
system_powershell_agent2 Uses powershell code to interact with
                         the operating system
TextPlugin               Allows the local computer to perform
                         string manipulations.
TimePlugin               Uses the local computer to obtain the
                         current time.
WebFileDownloadPlugin    Enables access to web content by
                         downloading it to the local computer.

This example uses the ListAvailable option to show all registered plugins. These plugins are available to be added to a session through the Add-ChatPlugin command, and can also configured through the Connect-ChatSession command or settings configuration.

.LINK
Add-ChatPlugin
Register-ChatPlugin
Remove-ChatPlugin
Unregister-ChatPlugin
Connect-ChatSession
#>
function Register-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $Name,

        [parameter(position=1)]
        [string] $Description,

        [parameter(parametersetname='existingplugin', valuefrompipeline=$true, mandatory=$true)]
        [Modulus.ChatGPS.Plugins.PowerShellPluginFunction] $Function
    )

    begin {
        $pluginTable = [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellPluginFunction]]::new()
    }

    process {
        $pluginTable.Add($Function.Name, $Function)
    }

    end {
        $generationScriptLocation = GetGenerationScriptLocation

        $newPlugin = [Modulus.ChatGPS.Plugins.PowerShellPluginProvider]::new($Name, $Description, $pluginTable, $generationScriptLocation)

        [Modulus.ChatGPS.Plugins.PluginProvider]::NewProvider($newplugin)
    }
}
