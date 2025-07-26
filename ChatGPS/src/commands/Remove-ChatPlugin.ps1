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
Removes a chat plugin associated with a session.

.DESCRIPTION
Remove-ChatPlugin removes a specified chat plugin from a session, and this means the plugin's capabilities such as local computer system or user resource access will no longer be triggered by ChatGPS command interactions with language models in that session. For more information regarding chat plugins and their capabilities, see the documentation for Add-ChatPlugin.

Note that Remove-ChatPlugin does not remove the chat plugin from the list of plugins registered as available to be added to a session through the Add-ChatPlugin command; built-in plugins that are available by default with ChatGPS can never be unregistered, but custom plugins registered using the Register-ChatPlugin command can be removed from the list of available plugins using the Unregister-ChatPlugin commmand.

If so desired, another instance of the same plugin could be restored to the session at a later time through the Add-ChatPlugin command.

By default, Remove-ChatPlugin removes plugins from the current session; specify the SessionName or Session parameters to remove the plugin from a session other than the current session.

.PARAMETER Name
The name of the chat plugin to remove. For a list of plugins that can be removed from the session, use the Get-ChatPlugin command targeting the appropriate session.

.PARAMETER SessionName
The name property of an existing session from which the specified plugin should be removed. If neither this parameter nor the Session parameter are specified, the plugin will be removed from the current session.

.PARAMETER Session
The session object (as returned by commands such as Get-ChatSession) ffrom which the plugin should be removed. If neither this nor the SessionName parameter are specified then the plugin will be removed from the current session.


.OUTPUTS
None.

.EXAMPLE
PS > Remove-ChatPlugin TimePlugin

In this example, the TimePlugin plugin is removed from the current session.

.EXAMPLE
PS > Get-ChatPlugin | Remove-ChatPlugin

In this example, all plugins are removed from the current session.

.LINK
Add-ChatPlugin
Get-ChatPlugin
Connect-ChatSession
Register-ChatPlugin
Unregister-ChatPlugin
#>
function Remove-ChatPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [string[]] $Name,

        [string] $SessionName,

        [Modulus.ChatGPS.Models.ChatSession] $Session
    )
    begin {
        $targetSession = if ( $Session ) {
            $Session
        } elseif ( $SessionName ) {
            Get-ChatSession $SessionName
        } else {
            Get-ChatSession -Current
        }
    }

    process {
        $targetSession.RemovePlugin($Name)
    }

    end {
    }
}

RegisterPluginCompleter Remove-ChatPlugin Name
RegisterSessionCompleter Remove-ChatSession SessionName
