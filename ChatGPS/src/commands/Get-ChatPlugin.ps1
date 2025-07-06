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
Gets chat plugins associated with a session, or obtains the list of all registered plugins that are available to be added to any session.

.DESCRIPTION
Get-ChatPlugin enumerates plugins that enable language model interactions initiated by ChatGPS commands to execute code on the local system. This allows language models to process information about the local system or other resources to which the user has access. Plugins also allow the local system to make changes to the local system or other resources accessible to the user, effectively allowing the model to act as an "agent" performing tasks on behalf of the user. Chat plugins are enabled for a given session, and by default sessions have no plugins, so chat session interactions with the model have no side effects and do not send information to the model beyond what is explicitly sent by the user to the model through ChatGPS commands.

To enable plugins for a session, the plugins must be explicitly specified when the session is created through Connect-ChatSession or settings configuration, or after session creation by using the Add-ChatPlugin command. Plugins may be removed from a session through the Remove-ChatPlugin command.

When no arguments are specifid, Get-ChatPlugin lists the plugins associated with the current session. The Name or Id parameters may be specified to return the plugins for a specific session by session name or session id respectively.

Use the ListAvailable parameter to enumerate all registered plugins, i.e. all possible plugins that could be assigned to any session through the Add-ChatPlugin command or by creating a new session. By default, ChatGPS supports a list of builtin pre-registered plugins, and additional plugins beyond this set may be registered and unregistered by the user through the Register-Plugin and Unregister-Plugin commands.

.PARAMETER Name
The name of the chat plugin to retrieve. When ListAvailable is not specified, the command returns a plugin with this name in the current session. If the ListAvailable flag is specified, then registered plugins that contain the specified value of this parameter in the name are returned, allowing the user to find available plugins related to a particular function specified by Name.

.PARAMETER SessionName
The name property of an existing session for which plugins added to that session should be retrived. If neither this nor the Session parameter are specified then plugins are enumerated from the current session.

.PARAMETER Session
The session object (as returned by commands such as Get-ChatSession) for which plugins added to that session should be retrived. If neither this nor the SessionName parameter are specified then plugins are enumerated from the current session.


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
function Get-ChatPlugin {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', position=0)]
        [parameter(parametersetname='bynamebysession', position=0, mandatory=$true)]
        [parameter(parametersetname='bynamebysessionname', position=0, mandatory=$true)]
        [parameter(parametersetname='listavailable', position=0)]
        [string] $Name,

        [parameter(parametersetname='bysessionname', mandatory=$true)]
        [parameter(parametersetname='bynamebysessionname', mandatory=$true)]
        [string] $SessionName,

        [parameter(parametersetname='bysession', valuefrompipeline=$true, mandatory=$true)]
        [parameter(parametersetname='bynamebysession', valuefrompipeline=$true, mandatory=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [parameter(parametersetname='listavailable', mandatory=$true)]
        [switch] $ListAvailable
    )

    begin {
        $filter = if ( $ListAvailable.IsPresent -and $Name ) {
            { $_.Name -like "*$($Name)*" }
        } else {
            { $true }
        }
    }

    process {
        $targetSession = if ( ! $ListAvailable.IsPresent ) {
            if ( $Session ) {
                $Session
            } elseif ( $SessionName ) {
                Get-ChatSession $SessionName
            } else {
                Get-ChatSession -Current
            }
        }

        $plugins = if ( ! $targetSession ) {
            [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviders()
        } else {
            if ( $Name ) {
                $targetSession.GetPlugin($Name)
            } else {
                $targetSession.Plugins
            }
        }

        $plugins | where $filter | sort-object Name
    }

    end {
    }
}

RegisterPluginCompleter Get-ChatPlugin Name
RegisterSessionCompleter Get-ChatPlugin SessionName
