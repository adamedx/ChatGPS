#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

class Function {
    hidden static [string] $captureGroupName = 'param'
    hidden static [System.Text.RegularExpressions.RegEx] $parameterMatcher = [System.Text.RegularExpressions.RegEx]::new("\{\{[`$](?<$([Function]::captureGroupName)>[a-zA-Z_][a-zA-Z0-9_]+)\}\}")
    hidden static [ScriptBlock] $FunctionNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $connection = $fakeBoundParameters['Connection']

        $targetConnection = if ( $connection ) {
            $Connection
        } else {
            GetCurrentSession $false
        }

        if ( $targetConnection ) {
            $sessionFunctions = $targetConnection.SessionFunctions
            $sessionFunctions.GetNamedFunctions().Name | where { $_.StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
        }
    }

    static [string[]] GetParametersFromDefinition([string] $definition) {
        # Find any pattern that looks like {{$somename}}
        $matchResults = [Function]::parameterMatcher.Matches($definition)
        $parameters = if ( $matchResults ) {
            $matchResults | foreach {
                $_.groups[[Function]::captureGroupName].Value
            }
        }

        return $parameters | select-object -unique
    }

    static [void] RegisterFunctionNameCompleter([string] $command, [string] $parameterName) {
        Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock ([Function]::FunctionNameCompleter)
    }
}

