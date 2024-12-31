#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

<#
.SYNOPSIS
Executes a "chat" function previously defined by the New-ChatFunction command; a chat function is a parameterized function defined by natural language.

.DESCRIPTION
Invoke-ChatFunction uses the language model associated with the session to process a chat function and returns its results as output. The New-ChatFunction command is used to define chat functions; a chat function is a function defined by a natural language prompt. An example of such a prompt could be "Show me the first {{$rows}} levels of Pascal's Triangle." The prompt syntax makes use of Handlebars templating syntax (https://handlebarsjs.com/) to define optional parameters to the function, in this case the parameter "rows" indicates the number of levels (or "rows") of the Pascal's Triangle object to output.

For more details on how to define a chat function, see the New-ChatFunction command documentation.

The function to process may by specified to Invoke-ChatFunction by its unique identiier or for functions that have a user defined name the name may also be specified. Chat functions can take parameters, so the Parameters parameter of Invoke-ChatFunction is used to specify any parameters for the function.

.PARAMETER Id
All chat functions have a unique identifier -- specify the unique identifier of the function to be processed using the Id parameter. Functions may also be specified by a user defined name through the Name parameter.

.PARAMETER Name
For a chat function given an optional friendly name, specify the function's name to the Name parameter in order to process the function with that name.

.PARAMETER Parameters
The Parameters parameter allows the parameters defined by the chat function to be specified. This parameter may be either an array or a Hashtabletype. If it is an array, then the parameters must be specified in the same order in which they are listed within the function's definition. If this parameter is a Hashtable, then the keys correspond to a chat function parameter name and the associated value for the key is the value of the parameter.

.PARAMETER Session
The chat session to which the command is targeted.

.OUTPUTS
The text function result output returned by the language model.

.EXAMPLE
In this example, the New-ChatFunction comamand is first used to create a new function named 'merger' that merges two sentences into a single sentence. When Invoke-ChatFunction is specified, the first parameter is the function name, followed by the parameters as an array using PowerShell's standard comma-separated list format for arrays. Specifying parameters by order is convenient, though if the function definition is changed in a way that the parameters are re-ordered then the order of parameters specified to Invoke-ChatFunction must also be changed to avoid incorrect behavior.

PS > New-ChatFunction -Name merger 'Provide a single sentence that has the same meaning as the individual sentences {{$sentence1}} and {{$sentence2}}'al sentences {{$sentence1}} and {{$sentence2}}'
PS > Invoke-ChatFunction merger "I use PowerShell.", "I use LLMs."

I use both PowerShell and LLMs.

.EXAMPLE
This example shows how Invoke-ChatFunction can accept parameters bound by name rather than order by specifying a Hashtable data type for the parameters parameter. This ensures that if the order of the parameters in a function definition changes, the Invoke-ChatFunction usage of that function will not be impacted.

PS > $pascal = New-ChatFunction 'Generate code that outputs the first {{$rows}} levels of Pascal's triangle using the programming language {{$language}}'e using the programming language {{$language}}'

PS > $pascal | Invoke-ChatFunction -parameters @{language='powershell';rows=3}

```powershell
# Function to generate Pascal's Triangle
function Generate-PascalsTriangle {
    param (
        [int]$levels
    )

    # Initialize triangle with the first row
    $triangle = @()
    $triangle += @(1)

    for ($i = 1; $i -lt $levels; $i++) {
        # Create a new row
        $row = @(1)

        # Calculate the values for the new row
        for ($j = 1; $j -lt $i; $j++) {
            $row += $triangle[$i - 1][$j - 1] + $triangle[$i - 1][$j]
        }
        $row += @(1)

        # Add the new row to the triangle
        $triangle += ,$row
    }

    return $triangle
}

# Generate and display the first 3 levels of Pascal's Triangle
$levels = 3
$pascalsTriangle = Generate-PascalsTriangle -levels $levels

# Output the triangle
foreach ($row in $pascalsTriangle) {
    Write-Host ($row -join ' ')
}
```

.EXAMPLE
Invoke-ChatFunction's output can be used with other PowerShell commands. In this case, invoke a function that translates natural language to PowerShell code, and this code is then executed within PowerShell. Note that executing code returned by a language model is risky since models cannot be relied upon to generate accurate or even safe code; when experimenting with such techniques, do so only in an environment where the code cannot access resources using your identity or otherwise interact with sensitive data.

PS > $scriptWriter = New-ChatFunction 'Generate PowerShell code that accomplishes the following goal {{$goal}}. Output only valid PowerShell that can be directly executed by the PowerShell interpreter. Do not include explanations or any markdown formatting, include only the code.'
PS > $scriptWriter | Invoke-ChatFunction -Parameters 'Show the processes that are top 3 in memory utilization' | Invoke-Expression

Name           Memory (MB)
----           -----------
devenv              725.98
XboxPcApp           450.52
msedgewebview2      440.34


.LINK
New-ChatFunction
Get-ChatFunction
Remove-ChatFunction
New-ChatScriptBlock
#>

function Invoke-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name,

        [parameter(parametersetname='name', position=1)]
        [parameter(parametersetname='id', position=0)]
        [object] $Parameters = $null,

        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {
        $targetSession = GetTargetSession $Session

        $sessionFunctions = GetSessionFunctions $targetSession

        $parameterValues = [System.Collections.Generic.Dictionary[string,object]]::new()

        $hasOrderedParameters = $Parameters -ne $null -and ! ( $Parameters -is [HashTable] )

        if ( $Parameters -is [HashTable] ) {
            foreach ( $parameterName in $Parameters.Keys ) {
                $parameterValues.Add($parameterName, $Parameters[$parameterName])
            }
        }
    }

    process {
        $function = if ( $Id ) {
            $sessionFunctions.GetFunctionById($Id)
        } else {
            $sessionFunctions.GetFunctionByName($Name)
        }

        $targetParameters = if ( ! $hasOrderedParameters ) {
            $parameterValues
        } else {
            $boundParameters = [System.Collections.Generic.Dictionary[string,object]]::new()

            $orderedParameterNames = [Function]::GetParametersFromDefinition($function.Definition)

            $parameterIndex = 0

            foreach ( $parameterValue in $Parameters ) {
                if ( $parameterIndex -ge $orderedParameterNames.Count ) {
                    throw [ArgumentException]::new("The function with identifier $($function.Id) and name '$($function.Name)' only has $($orderedParameterNames.Count) parameters but $($parameterIndex + 1) parameters were specified")
                }
                $boundParameters.Add($orderedParameterNames[$parameterIndex], $parameterValue)
                $parameterIndex++
            }

            $boundParameters
        }

        $result = $targetSession.InvokeFunctionAsync($function.Id, $targetParameters)

        if ( $result.IsFaulted ) {
            $exception = $result.Exception
            throw [ApplicationException]::new("An unexpected error occurred invoking the chat function", $exception)
        }

        $result.Result
    }

    end {
    }

}

[Function]::RegisterFunctionNameCompleter('Invoke-ChatFunction', 'Name')
