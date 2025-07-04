#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

<#
.SYNOPSIS
Creates a new "chat" function, a parameterized function defined by natural language using Handlebars (https://handlebarsjs.com/) templating syntax.

.DESCRIPTION
A chat function is simply a function defined by a natural language prompt. An example of such a prompt could be "Show me the first {{$rows}} levels of Pascal's Triangle." The prompt syntax makes use of Handlebars templating syntax (https://handlebarsjs.com/) to define optional parameters to the function, in this case the parameter "rows" indicates the number of levels (or "rows") of the Pascal's Triangle object to output.

The New-ChatFunction allows such functions to be defined so that they may be subsequently invoked by the Invoke-ChatFunction command. Chat functions can be bound to a user defined name for easy reference by other commands, or can otherwise be referenced by the function's automatically generated identifier.

Note that the related New-ChatScriptBlock function can also be used to bind such chat functions to native PowerShell functions, providing a convenient PowerShell wrapper syntax around the function's capabilities that obviates the need to use the dedicated Invoke-ChatFunction command.

All chat functions previously defined by New-ChatFunction can be enumerated using the Get-ChatFunction command. Chat functions can be undefined by the Remove-ChatFunction command.

.PARAMETER Definition
This mandatory parameter is a Handlebars template (https://handlebarsjs.com/) compatible string containing a natural language description of the function. Parameters are specified via the Handlebars syntax as alphanumeric identifiers prefixed with the '$' character and surrounded by two sets of '{}' characters, i.e. the parameter named 'rows" would appear inline with the function definition's natural language text as '{{$rows}}'.

.PARAMETER Name
The chat function can be given an optional friendly name for use with other function-related commands such as Invoke-ChatFunction or simply as a descriptive reminder of the function's purpose. The name must be unique -- if New-ChatFunction is specified with a Name parameter that is already assigned to a previously defined function, the command will fail unless the Force parameter is also specified, in which case the previously defined function is removed to preserve the name uniqueness condition.

.PARAMETER Force
Use the Force parameter to specify that default behavior to fail the command if the value of the Name parameter specified to the command has already been assigned to a function is overridden. In such a case, the previously existing function will no longer be associated with the name, which will be associated with the function defined by this invocation.

.OUTPUTS
A function object that describes the defined function and that may be passed as input to other commands that operate on functions such as Invoke-ChatFunction or Remove-ChatFunction.

.EXAMPLE
In this example, the New-ChatFunction command is used to define a function that translates text to a particular language -- both the text to be translated and the target language for translation are specified as parameters to the function:

PS > New-ChatFunction -name Translator 'Translate the text {{$sourcetext}} into the language {{$language}} and respond with output only in that language.'

Id                                   Name       Definition             Parameters
--                                   ----       ----------
59880abc-166f-48fd-a96d-220f793c4f57 Translator Translate the text {{$ {[language, language], [sourcetext, sourcetext]}

PS > Invoke-ChatFunction -Parameters 'I use PowerShell for both work and play.', Spanish

Uso PowerShell tanto para el trabajo como para el ocio.

.EXAMPLE
This example shows how to use a function created by New-ChatFunction that has no name. In this case, the output of New-ChatOutput is assigned to a variable that can be used with other function-related commands; here it is used via the pipeline to specify the function to be invoked by Invoke-ChatFunction

PS > $pascalFunction = New-ChatFunction -Name Pascal 'Show the first {{$rows}} levels of Pascals triangle's of Pascals triangle'
PS > $pascalFunction | Invoke-ChatFunction -Parameters 5

Pascal's Triangle is constructed by starting with a single "1" at the top (the 0th row), and then each number below it is the sum of the two numbers directly above it. Here are the first five levels (rows) of Pascal's Triangle:

```
       1       (Row 0)
      1 1      (Row 1)
     1 2 1     (Row 2)
    1 3 3 1    (Row 3)
   1 4 6 4 1   (Row 4)
```

.LINK
Invoke-ChatFunction
Get-ChatFunction
Remove-ChatFunction
New-ChatScriptBlock
#>
function New-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [string] $Definition,

        [parameter(position=1, ValueFromPipelineByPropertyName=$true)]
        [string] $Name,

        [switch] $Force
    )

    begin {
        $functions = GetFunctionInfo
    }

    process {
        $parameters = [Function]::GetParametersFromDefinition($Definition)

        $function = [Modulus.ChatGPS.Models.Function]::new($Name, $parameters, $Definition)
        $functions.AddFunction($function, $Force.IsPresent)

        $function
    }

    end {
    }
}
