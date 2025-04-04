#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

<#
.SYNOPSIS
Creates a parameterized PowerShell script block that invokes a chat function created by New-ChatFunction and optionally binds it to a PowerShell function.

.DESCRIPTION
New-ScriptBlock generates PowerShell script blocks based on a chat function definition, i.e. a natural language prompt as opposed to a typical PowerShell function defined using the PowerShell language. Such a script block serves as a native PowerShell "wrapper" for chat functions, making it easier to integrate chat functions with existing PowerShell scripts and modules. It also simplifies usage of such functions by obviating the need to use Invoke-ChatFunction and its less natural parameter binding syntax.

New-ScriptBlock can create a script block from an existing chat function and can also create a new chat function for the script block.

See the New-ChatFunction command documentation for additional information about chat functions.

The script block created by New-ChatScriptBlock will have parameters with the same names as the parameters of the chat function in the same positional order. The values of the script block parameters will be bound to the corresponding chat function parameters when the script block is invoked. The first parameter of the script block will be defined to come from the input pipeline unless the NoInputObject parameter of New-ChatScriptBlock is specified.

.PARAMETER Id
All chat functions have a unique identifier -- specify the unique identifier of the function to be returned using the Id parameter.

.PARAMETER FromChatFunctionName
Instead of using the Id parameter to create a script block for an existing chat function, use the FromChatFunctionName parameter to specify the chat function by its user-defined name.

.PARAMETER Definition
This parameter is a Handlebars template (https://handlebarsjs.com/) compatible string containing a natural language description of the function. Parameters are specified via the Handlebars syntax as alphanumeric identifiers prefixed with the '$' character and surrounded by two sets of '{}' characters, i.e. the parameter named 'rows" would appear inline with the function definition's natural language text as '{{$rows}}'.

.PARAMETER NoInputObjectParameterName
The script block is defined with one parameter for each of the chat function's parameters, in the same order and with the same names as in the chat function. By default, the first such parameter is defined to take input from the pipeline when the script is invoked. To skip this behavior, specify the NoInputObjectParameterName so that pipeline input will not be piped to the generated script block's first parameter.

.PARAMETER BindToNativeFunctionName
By default, the script block generated by the New-ChatScriptBlock is simply returned by the command and must be either saved in a variable or passed long the object pipeline for use by subsequent operations. To turn this generated script block into a native PowerShell function, specify the BindToNativeFunctionName parameter to create a PowerShell function with this script block; the generated function is usable just like any other PowerShell function and will execute the chat function specified to New-ChatScriptBlock when invoked.

.PARAMETER Force
Use the Force parameter to specify that default behavior to fail the command if the value of the Name parameter specified to the command has already been assigned to a function is overridden. In such a case, the previously existing function will no longer be associated with the name, which will be associated with the function defined by this invocation.

.OUTPUTS
A PowerShell script block that will execute the chat function specified to the New-ChatScriptBlock command when invoked; the parameters of the script block will be passed as parameters to the script block based on the parameter names.

.EXAMPLE
This example creates a new script block based on a chat function definition that extracts verbs from the input text passed to the chat function's 'text' parameter from the script block's corresponding 'text' parameter. The script block is saved in a variable and is then used in a foreach loop to process multiple inputs via invocation through the '.' dot-sourcing operator:

PS > $verbExtractor = New-ChatScriptBlock 'Extract all the verbs from the text {{$text}} and only the verbs -- do not emit any additional text or explanations.' not emit any additional text or explanations.'
PS > 'I ran to the store', 'I wrote PowerShell code', 'I went running.' | foreach { . $verbExtractor -text $_ }

ran
wrote
went, running

.EXAMPLE
This example is similar to the previous one, except that the input is passed using the pipeline rather than the generated parameter name:

PS > $verbExtractor = New-ChatScriptBlock 'Extract all the verbs from the text {{$text}} and only the verbs -- do not emit any additional text or explanations.' not emit any additional text or explanations.'
PS > 'I ran to the store', 'I wrote PowerShell code', 'I went running.' | . $verbExtractor

ran
wrote
went, running

.EXAMPLE
In this example, New-ScriptBlock is used with the BindToNativeFunctionName parameter to define a new PowerShell function Translate-Text. This powershell function has the same parameters as the chat function specified in the Definition parameter of New-ChatScriptBlock, and specifying those parameters via the function has the same effect as specifying them to the chat function when it is invoked.

PS > New-ChatScriptBlock 'Translate the text {{$sourcetext}} into the language {{$language}} and respond with output only in that language.' -BindToNativeFunctionName Translate-Text
PS > Translate-Text -sourcetext 'I can translate text using PowerShell!' -language Spanish
¡Puedo traducir texto usando PowerShell!

.EXAMPLE
As in the example above, the generated function also takes input from the pipeline, so output from one command can be sent to the command for processing. In this example, script

PS > New-ChatScriptBlock -BindToNativeFunctionName Classify-Text 'Classify the input text {{$inputtext}} according to what human or computer languages are contained in it, and respond with a comma separated list of these languages in order of descending prominence of each language in the text. Do not respond with anything else other than the comma separated list of languages.' | Out-Null
PS > Get-ChildItem -File * | foreach { $_ | Get-Content | Out-String } | Classify-Text

C#, JSON
English, JSON
JSON, HTML
JSON
Visual Studio Solution File, C#
PowerShell, JSON, Markdown

.EXAMPLE
The BindToNativeFunctionName parameter can be used to create a PowerShell function that can be used to execute the chat function instead of the less elegant Invoke-ChatFunction command -- in this example, a chat function that summarizes the functionality of PowerShell script code is turned into a PowerShell function, which is then executed as a command:

PS > New-ChatScriptBlock 'Summarize the purpose of the PowerShell code given by {{$powershellcode}} using no more than 5 sentences' -BindToNativeFunctionName Summarize-Script

PS > Get-Content ./New-ChatScriptBlock.ps1 | Out-String | Summarize-Script

The PowerShell code defines a function called `New-ChatScriptBlock`, which creates a parameterized PowerShell script block that integrates with a chat function defined by `New-ChatFunction`. This script block acts as a wrapper, allowing users to invoke chat functions using a more intuitive syntax, avoiding the complexities of the `Invoke-ChatFunction` command. The function supports specifying chat functions by their unique identifier or name, and allows for customization such as binding the script block to a native PowerShell function and controlling whether the first parameter accepts pipeline input. Overall, it simplifies the process of incorporating chat capabilities into PowerShell scripts.

.EXAMPLE
This example shows the capability of New-ChatScriptBlock to bind a script block to an existing chat function using the pipeline -- it also uses the BindToNativeFunctionName parameter to generate a PowerShell function for each existing named chat function:

PS > Get-ChatFunction | Where-Object { $_.name } | foreach { $_ | New-ChatScriptBlock -BindToNativeFunctionName "Invoke-Gen$($_.name)" }

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Invoke-GenPascal
Function        Invoke-GenMerger
Function        Invoke-GenTranslator

.LINK
New-ChatFunction
Invoke-ChatFunction
Get-ChatFunction
Remove-ChatFunction
#>
function New-ChatScriptBlock {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', mandatory=$true)]
        [Alias('Name')]
        [string] $FromChatFunctionName,

        [parameter(parametersetname='createnew', position=0, mandatory=$true)]
        [string] $Definition,

        [string] $InputObjectParameterName,

        [switch] $NoInputObject,

        [switch] $SimplePipeline,

        [string] $BindToNativeFunctionName,

        [switch] $Force
    )

    begin {

        # Note that this implementation has a dependency on both the interface AND semantics
        # of the Invoke-ChatFunction command

        $functions = GetFunctionInfo

        $blockStart = ""
        $blockEnd = ""

        if ( ! $SimplePipeline.IsPresent ) {
            $blockStart = @"
    begin { }
    process {
"@
            $blockEnd = @"
    }
    end { }
"@
        }
    }

    process {
        $functionSpecifier = $null

        $function = if ( $FromChatFunctionName ) {
            $functionSpecifier = "-Name '$FromChatFunctionName'"
            $functions.GetFunctionByName($FromChatFunctionName)
        } else {
            $functionById = if ($Id) {
                $functions.GetFunctionById($Id)
            } else {
                New-ChatFunction $Definition
            }
            $functionSpecifier = "-Id $($functionById.Id)"
            $functionById
        }

        $firstParameter = $true

        # By default, we want the first parameter of the generated scriptblock to come from pipeline input
        # as a usability enhancement, but the user can turn this off or specify a different parameter to take the input
        $argumentList = $function.Parameters.Keys | foreach {
            if ( $NoInputObject.IsPresent -or ( ! $firstParameter -and $_ -ne $InputObjectParameterName ) ) {
                "`$$_"
            } else {
                "[parameter(valuefrompipeline=`$true)] `$$_"
            }
            $firstParameter = $false
        }

        $argumentString = $argumentList | Join-string -Separator ','

        # The cast of PSBoundParameters to HashTable is required because apparently it has a different
        # type at different times with different casting behavior
        $scriptBlock = [ScriptBlock]::Create(
            @"
    param( $argumentString )
$blockStart
    Invoke-ChatFunction $functionSpecifier -Parameters ([HashTable] `$PSBoundParameters)
$blockEnd
"@
        )
        if ( $BindToNativeFunctionName ) {
            . $__ChatGPS_ModuleParentFunctionBuilder $BindToNativeFunctionName $scriptBlock $Force.IsPresent
        } else {
            $scriptBlock
        }
    }

    end {
    }
}

[Function]::RegisterFunctionNameCompleter('New-ChatScriptBlock', 'FromChatFunctionName')
