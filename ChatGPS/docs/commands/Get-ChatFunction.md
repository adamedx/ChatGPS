---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Get-ChatFunction

## SYNOPSIS
Retrieves all currently chat functions which are functions defined by natural language.

## SYNTAX

### id
```
Get-ChatFunction -Id <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### name
```
Get-ChatFunction [[-Name] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-ChatFunction enumerates chat functions defined by the New-ChatFunction command.
For more information about chat functions, see the documentation of the New-ChatFunction command.

The command can return all chat functions, or just a specific function based on a parameter that specifies a name or id for the function.
The output of Get-ChatFunction may also be used with other commands that operate on functions such as Invoke-ChatFunction, Remove-ChatFunction, etc.

## EXAMPLES

### EXAMPLE 1
```
Get-ChatFunction
 
Id                                   Name       Definition
--                                   ----       ----------
1e23861b-0beb-44fe-a515-8bf0c83138cb            Generate PowerShell code that accomplishes the following goal {{$goal}…
d7b26b42-241a-43e8-92f4-99df30a1f1ba Merger     Provide a single sentence that has the same meaning as the individual …
18677113-80ea-4aec-bebc-17f100cbf938 Pascal     Show the first {{$rows}} levels of Pascals triangle
b2869d25-7910-4846-be8a-677eab45500e Translator Translate the text {{$sourcetext}} into the language {{$language}}
```

Here Get-ChatFunction is specified with no parameters to retrieve all chat functions defined by invocaions of New-ChatFunction or New-ChaScriptBlock

### EXAMPLE 2
```
Get-ChatFunction Merger
 
Id                                   Name       Definition
--                                   ----       ----------
d7b26b42-241a-43e8-92f4-99df30a1f1ba Merger     Provide a single sentence that has the same meaning as the individual sentences combined
```

This example demonstrates specifying a value for the name parameter to return a function by name.

### EXAMPLE 3
```
Get-ChatFunction | Where-Object { ! $_.Name } | Remove-ChatFunction
```

This example enumerates all unnamed functions and removes them by piping them to the Remove-ChatFunction command:

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

### -Name
For a chat function given an optional friendly name, specify the function's name to the Name parameter in order to obtain the function with that name.

```yaml
Type: String
Parameter Sets: name
Aliases:

Required: False
Position: 1
Default value: None
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

### The chat function or functions given by the parameters specified to the command.
## NOTES

## RELATED LINKS

[New-ChatFunction
Invoke-ChatFunction
Remove-ChatFunction
New-ChatScriptBlock]()

