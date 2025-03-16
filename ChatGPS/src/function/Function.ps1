#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

class Function {
    hidden static [string] $captureGroupName = 'param'
    hidden static [System.Text.RegularExpressions.RegEx] $parameterMatcher = [System.Text.RegularExpressions.RegEx]::new('\{\{\$(?<' + ([Function]::captureGroupName) + '>([a-z]|[A-Z]|[0-9]|_)+)\}\}')
    hidden static [ScriptBlock] $FunctionNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $functions = GetFunctionInfo
        $functions.GetNamedFunctions().Name | where { $_.StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
    }

    static [string[]] GetParametersFromDefinition([string] $definition) {
        # Find any pattern that looks like {{$somename}}
        $matchResults = [Function]::parameterMatcher.Matches($definition)
        $parameters = if ( $matchResults ) {
            $matchResults.groups |
              where name -eq ([Function]::captureGroupName) |
              select-object -expandproperty value
        }

        if ( $parameters ) {
            # Parameters may be referenced more than once in a function definition, so ensure
            # we return only one name for each parameter.
            return $parameters | select-object -unique
        } else {
            return [string[]]::new(0)
        }
    }

    static [void] RegisterFunctionNameCompleter([string] $command, [string] $parameterName) {
        Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock ([Function]::FunctionNameCompleter)
    }
}

function GetFunctionInfo {
    [Modulus.ChatGPS.Models.FunctionTable]::GlobalFunctions
}
