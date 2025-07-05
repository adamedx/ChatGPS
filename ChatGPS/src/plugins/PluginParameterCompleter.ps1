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

function RegisterPluginCompleter([string] $command, [string] $parameterName) {
    $pluginNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters, $customProvidersOnly)

        $sessionParameterName = 'SessionName'

        $customProvidersOnly = $commandName -eq 'Unregister-ChatPlugin'

        # Note that switch parameters show as boolean types here rather than switch parameter types... ?
        $availablePluginsRequested = $customProvidersOnly -or ( $fakeBoundParameters.Contains('ListAvailable') -and $fakeBoundParameters['ListAvailable'] )

        $plugins = if ( $commandName -eq 'Add-ChatPlugin' -or $commandName -eq 'Connect-ChatSession' -or $availablePluginsRequested ) {
            # Hard-coding the command name here is not great, but I don't see the obvious way to parameterize
            # this completer other than using [ScriptBlock]::Create(). Confirmed that I used the Create()
            # approach in previous projects. Sigh.
            [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviders() | where {
                ! $customProvidersOnly -or $_.IsCustom()
            }
        } else {
            $targetSession = if ( $fakeBoundParameters.Contains($sessionParameterName) ) {
                Get-ChatSession -SessionName $fakeBoundParameters.Contains($sessionParameterName)
            } else {
                Get-ChatSession -Current
            }
            $targetSession.Plugins
        }

        if ( $plugins ) {
            $sortedPlugins = $plugins | sort-object $parameterName

            $sortedPlugins.Name | where { $_.ToString().StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
        }
    }

    Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock $pluginNameCompleter
}

function RegisterPluginParameterNameCompleter([string] $command, [string] $commandParameterName) {
    $pluginParameterCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $pluginCommandParameterName = 'PluginName'

        $currentPlugin = if ( $fakeBoundParameters.Contains($pluginCommandParameterName) ) {
            [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviders() |
              where Name -eq $fakeBoundParameters[$pluginCommandParameterName]
        }

        if ( $currentPlugin ) {
            $currentValue = $fakeBoundParameters[$parameterName]
            $currentPlugin.Parameters.Name |
              sort-object |
              where { $null -eq $currentValue -or $_ -notin $currentValue } |
              where-object {
                  $_.StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase)
              }
        }
    }

    Register-ArgumentCompleter -commandname $command -ParameterName $commandParameterName -ScriptBlock $pluginParameterCompleter
}

