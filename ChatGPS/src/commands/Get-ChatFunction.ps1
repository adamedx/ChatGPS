#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

<#
.SYNOPSIS
Retrieves the chat functions, functions defined by natural language, currently defined within a chat session.

.DESCRIPTION
Get-ChatFunction enumerates chat functions defined by the New-ChatFunction command. For more information about chat functions, see the documentation of the New-ChatFunction command.

The command can return all chat functions, or just a specific function based on a parameter that specifies a name or id for the function. The output of Get-ChatFunction may also be used with other commands that operate on functions such as Invoke-ChatFunction, Remove-ChatFunction, etc.

.PARAMETER Id
All chat functions have a unique identifier -- specify the unique identifier of the function to be returned using the Id parameter.

.PARAMETER Name
For a chat function given an optional friendly name, specify the function's name to the Name parameter in order to obtain the function with that name.

.PARAMETER Session
The chat session to which the command is targeted.

.OUTPUTS
The chat function or functions given by the parameters specified to the command.

.EXAMPLE
Specify Get-ChatFunction with no parameters to retrieve all chat functions defined for the current session.

PS > Get-ChatFunction

Id                                   Name       Definition
--                                   ----       ----------
1e23861b-0beb-44fe-a515-8bf0c83138cb            Generate PowerShell code that accomplishes the following goal {{$goal}…
d7b26b42-241a-43e8-92f4-99df30a1f1ba Merger     Provide a single sentence that has the same meaning as the individual …
18677113-80ea-4aec-bebc-17f100cbf938 Pascal     Show the first {{$rows}} levels of Pascals triangle
b2869d25-7910-4846-be8a-677eab45500e Translator Translate the text {{$sourcetext}} into the language {{$language}}

.EXAMPLE
Specify a value for the name parameter to return a function by name.

PS > Get-ChatFunction Merger

Id                                   Name       Definition
--                                   ----       ----------
d7b26b42-241a-43e8-92f4-99df30a1f1ba Merger     Provide a single sentence that has the same meaning as the individual …

.EXAMPLE
This example enumerates all unnamed functions and removes them by piping them to the Remove-ChatFunction command:

PS > Get-ChatFunction | Where-Object { ! $_.Name } | Remove-ChatFunction

.LINK
New-ChatFunction
Invoke-ChatFunction
Remove-ChatFunction
New-ChatScriptBlock
#>
function Get-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0)]
        [string] $Name,

        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
        $targetSession = if ( $Session ) {
            $Session
        } else {
            GetCurrentSession $true
        }

        $sessionFunctions = $targetSession.SessionFunctions
    }

    process {
        if ( $Id ) {
            $sessionFunctions.GetFunctionById($Id)
        } elseif ( $Name ) {
            $sessionFunctions.GetFunctionByName($Name)
        } else {
            $sessionFunctions.GetFunctions()
        }
    }

    end {
    }
}

[Function]::RegisterFunctionNameCompleter('Get-ChatFunction', 'Name')
