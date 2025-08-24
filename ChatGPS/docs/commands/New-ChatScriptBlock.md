---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# New-ChatScriptBlock

## SYNOPSIS
Creates a parameterized PowerShell script block that invokes a chat function created by New-ChatFunction and optionally binds it to a PowerShell function.

## SYNTAX

### id
```
New-ChatScriptBlock -Id <Guid> [-InputObjectParameterName <String>] [-NoInputObject] [-SimplePipeline]
 [-BindToNativeFunctionName <String>] [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### name
```
New-ChatScriptBlock -FromChatFunctionName <String> [-InputObjectParameterName <String>] [-NoInputObject]
 [-SimplePipeline] [-BindToNativeFunctionName <String>] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### createnew
```
New-ChatScriptBlock [-Definition] <String> [-InputObjectParameterName <String>] [-NoInputObject]
 [-SimplePipeline] [-BindToNativeFunctionName <String>] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
New-ScriptBlock generates PowerShell script blocks based on a chat function definition, i.e.
a natural language prompt as opposed to a typical PowerShell function defined using the PowerShell language.
Such a script block serves as a native PowerShell "wrapper" for chat functions, making it easier to integrate chat functions with existing PowerShell scripts and modules.
It also simplifies usage of such functions by obviating the need to use Invoke-ChatFunction and its less natural parameter binding syntax.

New-ScriptBlock can create a script block from an existing chat function and can also create a new chat function for the script block.

See the New-ChatFunction command documentation for additional information about chat functions.

The script block created by New-ChatScriptBlock will have parameters with the same names as the parameters of the chat function in the same positional order.
The values of the script block parameters will be bound to the corresponding chat function parameters when the script block is invoked.
The first parameter of the script block will be defined to come from the input pipeline unless the NoInputObject parameter of New-ChatScriptBlock is specified.

NOTE: Chat functions require a language model to be accessible from a ChatGPS session, and they also depend on ChatGPS.
If the function's behavior could be accomplished without the capabilities of language models to process natural language or unstructured data, consider using the Generate-ChatCode command instead which uses the language model to generate traditional code that can then be used any number of times without using a language model at all and even without ChatGPS, all at a much computationally lower cost.
See the documentation for Generate-ChatCode for more details.

## EXAMPLES

### EXAMPLE 1
```
$verbExtractor = New-ChatScriptBlock 'Extract all the verbs from the text {{$text}} and only the verbs -- do not emit any additional text or explanations.' not emit any additional text or explanations.'
PS > 'I ran to the store', 'I wrote PowerShell code', 'I went running.' | foreach { . $verbExtractor -text $_ }
 
ran
wrote
went, running
```

This example creates a new script block based on a chat function definition that extracts verbs from the input text passed to the chat function's 'text' parameter from the script block's corresponding 'text' parameter.
The script block is saved in a variable and is then used in a foreach loop to process multiple inputs via invocation through the '.' dot-sourcing operator.

### EXAMPLE 2
```
$verbExtractor = New-ChatScriptBlock 'Extract all the verbs from the text {{$text}} and only the verbs -- do not emit any additional text or explanations.' not emit any additional text or explanations.'
PS > 'I ran to the store', 'I wrote PowerShell code', 'I went running.' | . $verbExtractor
 
ran
wrote
went, running
```

This example is similar to the previous one, except that the input is passed using the pipeline rather than the generated parameter name.

### EXAMPLE 3
```
New-ChatScriptBlock 'Translate the text {{$sourcetext}} into the language {{$language}} and respond with output only in that language.' -BindToNativeFunctionName Translate-Text
PS > Translate-Text -sourcetext 'I can translate text using PowerShell!' -language Spanish
¡Puedo traducir texto usando PowerShell!
```

In this example, New-ScriptBlock is used with the BindToNativeFunctionName parameter to define a new PowerShell function Translate-Text.
This powershell function has the same parameters as the chat function specified in the Definition parameter of New-ChatScriptBlock, and specifying those parameters via the function has the same effect as specifying them to the chat function when it is invoked.

### EXAMPLE 4
```
New-ChatScriptBlock -BindToNativeFunctionName Classify-Text 'Classify the input text {{$inputtext}} according to what human or computer languages are contained in it, and respond with a comma separated list of these languages in order of descending prominence of each language in the text. Do not respond with anything else other than the comma separated list of languages.' | Out-Null
PS > Get-ChildItem -File * | foreach { $_ | Get-Content | Out-String } | Classify-Text
 
C#, JSON
English, JSON
JSON, HTML
JSON
Visual Studio Solution File, C#
PowerShell, JSON, Markdown
```

As in the example above, the generated function also takes input from the pipeline, so output from one command can be sent to the command for processing.
In this example, script

### EXAMPLE 5
```
New-ChatScriptBlock 'Summarize the purpose of the PowerShell code given by {{$powershellcode}} using no more than 5 sentences' -BindToNativeFunctionName Summarize-Script
 
Get-Content ./New-ChatScriptBlock.ps1 | Out-String | Summarize-Script
```

The BindToNativeFunctionName parameter is be used to create a PowerShell function called Summarize-Script that can be used to execute the chat function instead of the less elegant Invoke-ChatFunction command -- in this example, a chat function that summarizes the functionality of PowerShell script code is turned into a PowerShell function, which is then executed as a command.
The use of BindToNativeFunction provides a more seamless developer experience such that externally the chat function appears just like any other native PowerShell function or comman.

### EXAMPLE 6
```
Get-ChatFunction | Where-Object { $_.name } | foreach { $_ | New-ChatScriptBlock -BindToNativeFunctionName "Invoke-Gen$($_.name)" }
 
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Invoke-GenPascal
Function        Invoke-GenMerger
Function        Invoke-GenTranslator
```

This example shows the capability of New-ChatScriptBlock to bind a script block to an existing chat function using the pipeline -- it also uses the BindToNativeFunctionName parameter to generate a PowerShell function for each existing named chat function.

## PARAMETERS

### -Id
All chat functions have a unique identifier -- specify the unique identifier of the function to be returned using the Id parameter.

```yaml
Type: Guid
Parameter Sets: id
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FromChatFunctionName
Instead of using the Id parameter to create a script block for an existing chat function, use the FromChatFunctionName parameter to specify the chat function by its user-defined name.

```yaml
Type: String
Parameter Sets: name
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Definition
This parameter is a Handlebars template (https://handlebarsjs.com/) compatible string containing a natural language description of the function.
Parameters are specified via the Handlebars syntax as alphanumeric identifiers prefixed with the '$' character and surrounded by two sets of '{}' characters, i.e.
the parameter named 'rows" would appear inline with the function definition's natural language text as '{{$rows}}'.

```yaml
Type: String
Parameter Sets: createnew
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObjectParameterName
{{ Fill InputObjectParameterName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoInputObject
{{ Fill NoInputObject Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SimplePipeline
{{ Fill SimplePipeline Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BindToNativeFunctionName
By default, the script block generated by the New-ChatScriptBlock is simply returned by the command and must be either saved in a variable or passed long the object pipeline for use by subsequent operations.
To turn this generated script block into a native PowerShell function, specify the BindToNativeFunctionName parameter to create a PowerShell function with this script block; the generated function is usable just like any other PowerShell function and will execute the chat function specified to New-ChatScriptBlock when invoked.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Use the Force parameter to specify that default behavior to fail the command if the value of the Name parameter specified to the command has already been assigned to a function is overridden.
In such a case, the previously existing function will no longer be associated with the name, which will be associated with the function defined by this invocation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### A PowerShell script block that will execute the chat function specified to the New-ChatScriptBlock command when invoked; the parameters of the script block will be passed as parameters to the script block based on the parameter names.
## NOTES

## RELATED LINKS

[New-ChatFunction
Invoke-ChatFunction
Get-ChatFunction
Remove-ChatFunction]()

