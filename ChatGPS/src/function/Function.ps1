#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

class Function {
    hidden static [string] $captureGroupName = 'param'
    hidden static [System.Text.RegularExpressions.RegEx] $parameterMatcher = [System.Text.RegularExpressions.RegEx]::new("\{\{[`$](?<$([Function]::captureGroupName)>[a-zA-Z_][a-zA-Z0-9_]+)\}\}")
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
}

