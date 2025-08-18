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
Generates (builds) programming language code including PowerShell scripts from a natural language specification. Typically accessed through the Generate-ChatCode alias.

.DESCRIPTION
The Build-ChatCode command, usually invoked through its alias Generate-ChatCode, generates programming language code for any language, including PowerShell, according to the abilities of the language model used by the associated chat session. By default the target language is PowerShell itself, and in this situation the format of the command's output is a PowerShell script block parameterized according to the natural langauge specification. For languages other than PowerShell the output is simply the source code as a text string.

Througout the remaining documentation the alias Generate-ChatCode will be used to refer to Build-ChatCode.

The output can be executed or compiled as is appropriate for the target language. When the output is a PowerShell script block, it can be invoked with parameters just like any PowerShell script block. PowerShell output can also be written to a .ps1 file, where by default it is decorated with the [CmdletBinding] such that the file can be executed like any PowerShell script file. For other languages, the text can be operated on (i.e. compiled or executed) like any code for that language.

The function to process may by specified to Invoke-ChatFunction by its unique identiier or for functions that have a user defined name the name may also be specified. Chat functions can take parameters, so the Parameters parameter of Invoke-ChatFunction is used to specify any parameters for the function.

NOTE: Applications of code generation through Generate-ChatCode extend beyond the command's most immediate ability. Code generation may be used to replace costly LLM interactions by transforming natural language into code once, and in the future reusing the same code in place of the natural language.

.PARAMETER Definition
The Definition parameter is a natural language description of the desired functionality of the generated code. The language model can parameterize the code, and in the case of PowerShell the parameters will be explicitly modeled in the generated code unless the definition contains instructions otherwise.

.PARAMETER FunctionName
Optional name of a PowerShell function (i.e. command) to be bound to the output of this function when it generates a PowerShell scriptblock. This allows you to generate then invoke the generated code just like any human-authored command and reused multipled times without invoking the Generate-ChatCode command again.

.PARAMETER Language
Specifies the target language of the generated code; it can be any language supported by the language model of the associated session, and the effectiveness of the generated code for a given language will likely vary with each model. By default the target language is PowerShell, and the result output will be a PowerShell ScriptBlock with paramters inferred from the description, and a [cmdletbinding] attribute so that it can use standard PowerShell common parameter features. If the language is one other than PowerShell, the generated code is simply returned as a string. In the PowerShell case, the output format can be forced to string using the NoScriptBlock parameter and the automatic addition of the [cmdletbinding] parameter can be omitted with the NoCmdletBinding parameters.

.PARAMETER CustomGenerationInstructions
Specify this parameter to include additional instructions to the code generator. This is useful when processing multiple natural language specifications through the Definition parameter via the pipeline when there is a need to provide consistent generation instructions across multiple definitions (as in the case of reading multiple definitions from files for instance).

.PARAMETER NoScriptBlock
Specify NoScriptBlock to for the output of the command to be a string rather than a PowerShell script block when PowerShell is the target language. For other target languages this parameter has no effect.

.PARAMETER NoCmdletBinding
Specifies that the [CmdletBinding] attribute should not be automatically added to generated PowerShell script blocks. This parameter is ignored for target languages other than PowerShell.

.PARAMETER MaxAttempts
Specifies the maximum number of times to contact the language model to request code generation. Typically a single request should suffice, but models sometimes generate code with errors; the command attempts to validate code generated by the model, and if this validation fails (e.g. the code is not well-formed in the target language or would otherwise generate runtime or compile time errors) it tries again up to the maximum number of attempts.

.PARAMETER SessionName
Optional name of a specific chat session to use for accessing the AI language model. By default, the current session is used.

.PARAMETER Force
Specify the Force parameter to 
Specify this parameter to control whether plugins added to the associated session may be used as part of code generation. For example, code generation may use internet searches to obtain examples of relevant code that may aid the model in generating a better result.

.PARAMETER Parameters
The Parameters parameter allows the parameters defined by the chat function to be specified. This parameter may be either an array or a Hashtable type. If it is an array, then the parameters must be specified in the same order in which they are listed within the function's definition. If this parameter is a Hashtable, then the keys correspond to a chat function parameter name and the associated value for the key is the value of the parameter.

.PARAMETER Session
The chat session to which the command is targeted.

.OUTPUTS
The code generated by the language model in the target language. If the target language is PowerShell the output defaults to the PowerShell script block unless overridden with the NoScriptBlock parameter, in which case the output format is just a string. For all other languages the output type of the code is string.

.EXAMPLE
Generate-ChatCode 'For a given file path return its file version information' -FunctionName Get-FileVersion
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)
 
# Check if the file exists
if (-Not (Test-Path -Path $FilePath -PathType Leaf)) {
    Throw "File not found: $FilePath"
}
 
# Get the file version info
$fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath)
 
# Return the file version information object
$fileVersionInfo
 
PS > Get-FileVersion (Get-Command pwsh | Select-Object -ExpandProperty Source)

Here a new command, Get-FileVersion, is generated from instructions to determine the version information for a given file. The new command is then used to show the version of the executable for PowerShell, pwsh. When used with the FunctionName parameter to create the function, the outupt can be piped to Out-Null to avoid the display of the code in the terminal, though the output can be useful for inspecting the quality and accuracy of the generated code.

.EXAMPLE
Generate-ChatCode "Generate list of all prime numbers less than a given number N"
[cmdletbinding()]
param (
    [int]$N
)
function IsPrime($num) {
    if ($num -le 1) { return $false }
    for ($i = 2; $i -lt [math]::Sqrt($num) + 1; $i++) {
        if ($num % $i -eq 0) { return $false }
    }
    return $true
}
 
# Create an array to hold prime numbers
$primeNumbers = @()
 
# Iterate through numbers less than N and add primes to the list
for ($i = 2; $i -lt $N; $i++) {
    if (IsPrime($i)) {
        $primeNumbers += $i
    }
}
$primeNumbers

In this example Generate-ChatCode is used to generate code that can list prime numbers less than a given value. Note that the
natural language definition implied a parameter 'N' and the generated script has a parameter with this explicit name. Also
note that the generated code starts with [Cmdletbinding()], making it suitable for saving to a .ps1 PowerShell script file
and then using that file directly as a script.

.EXAMPLE
"Generate list of all prime numbers less than a given number N" | Generate-ChatCode -FunctionName Get-Primes | out-null
PS > Get-Primes 10
2
3
5
7

This example uses the same natural language definition as the previous case to generate prime numbers, but this time the FunctionName
parameter is specified and this creates a PowerShell function (same as can be created using the function keyword in PowerShell itself or
by adding a ScriptBlock to the function: drive through the New-Item command). After the command completes, the new function Get-Primes
is executed with a parameter of 10 and displays the expected results of prime numbers less than 10. Note also that in this case
the pipeline is used

.EXAMPLE
Generate-ChatCode "Get the top N processes by memory utilization. Please include the process name, process id, memory utilization, and start time. Be sure to use the correct field names for the aforementioned fields. The results must be sorted in descending order of the field used for memory utilization." | Out-File ~/documents/Get-MemoryProcesses.ps1
PS > & Get-TopMemoryProcesses -TopN 4
 
Name              Id MemoryUsageMB StartTime
----              -- ------------- ---------
devenv         24280        772.44 6/29/2025 8:05:24 AM
msedge         16440        409.95 6/29/2025 6:33:13 AM
msedge         62116        364.50 7/3/2025 6:55:18 PM
msedgewebview2 13196        339.33 6/29/2025 6:34:30 AM

In this example, the command is used to generate a PowerShell script and save it to a PowerShell script file. The file is then executed,
and when tab completion is used, it reveals a parameter 'TopN', and with the value of 4 specified the list of the top 4 processes
by memory is emitted by the generated code of the new script.

.EXAMPLE
"Generate list of all prime numbers less than a given number N" | Generate-ChatCode -Language python
def is_prime(num):
    if num <= 1:
        return False
    for i in range(2, int(num**0.5) + 1):
        if num % i == 0:
            return False
    return True
 
def list_primes_less_than_n(N):
    primes = []
    for number in range(2, N):
        if is_prime(number):
            primes.append(number)
    return primes
 
# Example usage:
N = 20
prime_numbers = list_primes_less_than_n(N)
print(prime_numbers)  # Output will be all prime numbers less than 20

This examples shows how the Generate-ChatCode command can be used to generate code for languages other than PowerShell for
the exact same natural language prompt used in the previous PowerShell examples.

.EXAMPLE
"Generate list of all prime numbers less than a given number N" | Generate-ChatCode -Language python | python3
[2, 3, 5, 7, 11, 13, 17, 19]

This example for python is similar to the previous one, except that the generated code is piped to the python3 command which is
the interpreter for the Python language installed on the current system. Note that this generated code is similar to the previous
example and does not provide a way to send arbitrary input to the Python interpret, but since the code also includes a sample invocation
of the function it generated with a value of '20', we get the output of all primes less than 20. This example demonstrates that
the command can be used to generate code for arbitrary languages that will execute.

To solve the parameter passing problem for non-PowerShell languages, workarounds include directing the code generator to create code
that reads input from environment variables or a file, or generating PowerShell code with code embedded in the non-PowerShell language
and using the Powershell code generate a string of the target language at runtime that invokes the embedded code with the values of
parameters passed to the outer PowerShell script block's parameters.Kthat uses the parameters passed in the PowerShell code's
script block.

.LINK
New-ChatScriptBlock
#>

function Build-ChatCode {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='nofunction')]
    [OutputType([ScriptBlock])]
    param(
        [parameter(position=0, valuefrompipeline=$true, mandatory=$true)]
        [string] $Definition,

        [parameter(parametersetname='function', mandatory=$true)]
        [Alias('Function')]
        [string] $FunctionName,

        [string] $Language = 'PowerShell',

        [string] $CustomGenerationInstructions,

        [switch] $NoScriptBlock,

        [switch] $NoCmdletBinding,

        [switch] $SkipModelSelfAssessment,

        [switch] $SkipModelErrorDetection,

        [int] $MaxAttempts = 3,

        [string] $SessionName,

        [string] $VerifierSessionName,

        [parameter(parametersetname='function')]
        [switch] $Force
    )

    begin {
        if ( $MaxAttempts -gt 50 ) {
            throw new [ArgumentException]::new("The specified MaxAttempts value of $($MaxAttempts) exceeds the maximum allowed value of 50 for this parameter")
        }

        $targetSession = if ( $SessionName ) {
            Get-ChatSession $SessionName
        } else {
            Get-ChatSession -Current
        }

        $targetVerifierSession = if ( $VerifierSessionName ) {
            Get-ChatSession $VerifierSessionName
        }
    }

    process {

        $generationResult = GenerateCodeForLanguage $Language $Definition $targetSession $MaxAttempts $CustomGenerationInstructions $NoCmdletBinding.IsPresent $SkipModelSelfAssessment.IsPresent $SkipModelErrorDetection.IsPresent $targetVerifierSession

        write-verbose "Code generation accessed the AI model $($generationResult.ModelAttempts) times."

        if ( ! $generationResult.GenerationException ) {
            $scriptBlockResult = $generationResult.ExecutableScriptBlock

            if ( $scriptBlockResult -and ! $NoScriptBlock.IsPresent ) {
                $generationResult.ExecutableScriptBlock
            } else {
                $generationResult.CodeText
            }

            if ( $FunctionName ) {
                if ( $scriptBlockResult ) {
                    (. $__ChatGPS_ModuleParentFunctionBuilder $FunctionName $scriptBlockResult $Force.IsPresent ) | out-null
                } else {
                    write-error "The FunctionName parameter was specified with a value of '$($FunctionName)', but the generated code did not result in a PowerShell script block so it could not be bound to a PwoerShell function with the specified name."
                }
            }
        } else {
            write-error $generationResult.GenerationException
        }
    }

    end {
    }
}

RegisterSessionCompleter Build-ChatCode SessionName
RegisterSessionCompleter Build-ChatCode VerifierSessionName SessionName
