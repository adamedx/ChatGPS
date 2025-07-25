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

$InvokeChatFunctionJobCount = 0

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
The Parameters parameter allows the parameters defined by the chat function to be specified. This parameter may be either an array or a Hashtable type. If it is an array, then the parameters must be specified in the same order in which they are listed within the function's definition. If this parameter is a Hashtable, then the keys correspond to a chat function parameter name and the associated value for the key is the value of the parameter.

.PARAMETER Session
The chat session to which the command is targeted.

.PARAMETER AsJob
Specifies that the command should be executed asynchronously as a job; this is useful when the interaction is expected to be slow due to significant token processing, inference complexity, or slow inferencing (e.g. inferencing with only CPU and no GPU). Instead of returning the results of the language model interaction, the command returns a job that can be managed using standard job commands like Get-Job, Wait-Job, and Receive-Job. Use Receive-Job to obtain the results that would normally be returned without AsJob.

.OUTPUTS
The text function result output returned by the language model.

.EXAMPLE
New-ChatFunction -Name merger 'Provide a single sentence that has the same meaning as the individual sentences {{$sentence1}} and {{$sentence2}}'
PS > Invoke-ChatFunction merger "I use PowerShell.", "I use LLMs."
 
I use both PowerShell and LLMs.

In this example, the New-ChatFunction comamand is first used to create a new function named 'merger' that merges two sentences into a single sentence. When Invoke-ChatFunction is specified, the first parameter is the function name, followed by the parameters as an array using PowerShell's standard comma-separated list format for arrays. Specifying parameters by order is convenient, though if the function definition is changed in a way that the parameters are re-ordered then the order of parameters specified to Invoke-ChatFunction must also be changed to avoid incorrect behavior.

.EXAMPLE
$pascal = New-ChatFunction 'Generate code that outputs the first {{$rows}} levels of Pascals triangle using the programming language {{$language}}'
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
 
This example shows how Invoke-ChatFunction can accept parameters bound by name rather than order by specifying a Hashtable data type for the parameters parameter. This ensures that if the order of the parameters in a function definition changes, the Invoke-ChatFunction usage of that function will not be impacted.

.EXAMPLE
$scriptWriter = New-ChatFunction 'Generate PowerShell code that accomplishes the following goal {{$goal}}. Output only valid PowerShell that can be directly executed by the PowerShell interpreter. Do not include explanations or any markdown formatting, include only the code.'
PS > $scriptWriter | Invoke-ChatFunction -Parameters 'Show the processes that are top 3 in memory utilization' | Invoke-Expression
 
Name           Memory (MB)
----           -----------
devenv              725.98
XboxPcApp           450.52
msedgewebview2      440.34

Invoke-ChatFunction's output can be used with other PowerShell commands. In this case, invoke a function that translates natural language to PowerShell code, and this code is then executed within PowerShell. Note that executing code returned by a language model is risky since models cannot be relied upon to generate accurate or even safe code; when experimenting with such techniques, do so only in an environment where the code cannot access resources using your identity or otherwise interact with sensitive data.

.EXAMPLE
Set-ChatAgentAccess -Allowed
PS > scriptAnalyzer = New-ChatFunction 'Summarize in three sentences or less the purpose of the PowerShell code at the local file system location {{$path}}'
PS > $scriptAnalyzer | Invoke-ChatFunction -Parameters .\commands\Invoke-ChatFunction.ps1
 
Id      Name                    PSJobTypeName   State      HasMoreData
--      ----                    -------------   -----      -----------
13      Invoke-ChatFunctionJob5 ThreadJob       Running    False
 
PS > Wait-Job Invoke-ChatFunctionJob5 | Receive-Job -Wait
 
The PowerShell code in `Invoke-ChatFunction.ps1` defines a function that executes previously defined "chat" functions using natural language prompts. These functions are created with the `New-ChatFunction` command and can accept parameters specified by the user, allowing interaction with a language model to process the prompts and return the results. Additionally, it supports running the function asynchronously as a background job to handle time-consuming computations.

This example shows how to invoke a chat function asynchronously as a PowerShell job using the AsJob parameter, and also demonstrates the way in which chat plugins can be used with chat functions to allow the function to access local or other user resources. In this case, the FileIOPlugin is added to the session so that when the chat function is invoked, it can read the contents of the file in the given path and then summarize it according to the natural language instructions provided as the function's definition.

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

        [parameter(parametersetname='definition', mandatory=$true)]
        [string] $Definition,

        [object] $Parameters = $null,

        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [switch] $AsJob
    )

    begin {
        $targetSession = GetTargetSession $Session $true

        $functions = GetFunctionInfo

        $parameterValues = [System.Collections.Generic.Dictionary[string,object]]::new()

        $hasOrderedParameters = $Parameters -ne $null -and ! ( $Parameters -is [HashTable] )

        if ( $Parameters -is [HashTable] ) {
            foreach ( $parameterName in $Parameters.Keys ) {
                $parameterValues.Add($parameterName, $Parameters[$parameterName])
            }
        }

        $definitionParameters = $null

        $temporaryFunction = if ( $Definition ) {
            $definitionParameters = [Function]::GetParametersFromDefinition($Definition)
            [Modulus.ChatGPS.Models.Function]::new($null, $definitionParameters, $Definition)
        }

        $jobBoundParameters = @{}
        $jobFunctions = @()

        if ( ! $AsJob.IsPresent ) {
            SendConnectionTestMessage $targetSession $true
        } else {
            $PSBoundParameters.Keys | foreach {
                if ( $_ -notin 'AsJob', 'Session', 'Id', 'Name', 'FunctionDefinition' ) {
                    $jobBoundParameters.Add($_, $PSBoundParameters[$_])
                }
            }
        }
    }

    process {

        $function = if ( $Id ) {
            $functions.GetFunctionById($Id)
        } elseif ( $Name ) {
            $functions.GetFunctionByName($Name)
        } else {
            $temporaryFunction
        }

        if ( $AsJob.IsPresent ) {
            $jobFunctions += $function
            return
        }

        $targetParameters = if ( ! $hasOrderedParameters ) {
            $parameterValues
        } else {
            $boundParameters = [System.Collections.Generic.Dictionary[string,object]]::new()

            $orderedParameterNames = $definitionParameters -eq $null ?
                [Function]::GetParametersFromDefinition($function.Definition) :
                $definitionParameters

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

        $result = try {
            if ( $temporaryFunction ) {
                $functions.AddFunction($function, $false)
            }

            $targetSession.InvokeFunctionAsync($function.Id, $targetParameters)
        } finally {
            if ( $temporaryFunction ) {
                $functions.RemoveFunction($function.id)
            }
        }

        if ( $result.IsFaulted ) {
            $exception = $result.Exception
            throw [ApplicationException]::new("An unexpected error occurred invoking the chat function", $exception)
        }

        $result.Result
    }

    end {
        if ( $AsJob.IsPresent ) {
            $script:InvokeChatFunctionJobCount++
            Start-ThreadJob -Name "Invoke-ChatFunctionJob$($script:InvokeChatFunctionJobCount)" `
              -InitializationScript {
              set-item env:CHATGPS_SETTINGS_IGNORE_DUPLICATE_REGISTER_PLUGIN $true
                  $erroractionpreference = 'stop'
              } -ScriptBlock {
                  param($functions, $session, $parameters, $module)
                  $module | import-module
                  $functions | Invoke-ChatFunction -Session $session @parameters
              } -ArgumentList $jobFunctions,
                $targetSession,
                $jobBoundParameters,
                $myinvocation.mycommand.Module
        }
    }

}

[Function]::RegisterFunctionNameCompleter('Invoke-ChatFunction', 'Name')

