#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function RegisterPluginCompleter([string] $command, [string] $parameterName) {
    $pluginNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $sessionParameterName = 'SessionName'

        # Note that switch parameters show as boolean types here rather than switch parameter types... ?
        $availablePluginsRequested = $fakeBoundParameters.Contains('ListAvailable') -and $fakeBoundParameters['ListAvailable']

        $plugins = if ( $commandName -eq 'Add-ChatPlugin' -or $availablePluginsRequested ) {
            # Hard-coding the command name here is not great, but I don't see the obvious way to parameterize
            # this completer other than using [ScriptBlock]::Create(). Confirmed that I used the Create()
            # approach in previous projects. Sigh.
            [Modulus.ChatGPS.Plugins.Plugin]::GetPlugins()
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
