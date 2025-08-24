---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Remove-ChatFunction

## SYNOPSIS
Removes a chat function created by the New-ChatFunction command.

## SYNTAX

### id
```
Remove-ChatFunction -Id <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### name
```
Remove-ChatFunction [-Name] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
A chat function is created by the New-ChatFunction command.
Chat functions can be specified to the Remove-ChatFunction command via the Id property of the function, or if the function has a name, its name can be used to identify the function to be deleted.

## EXAMPLES

### EXAMPLE 1
```
Remove-ChatFunction Summarizer
```

In this example, the chat function named Summarizer is deleted by specifying the Name property of the function to be deleted.

### EXAMPLE 2
```
Get-ChatFunction
Id                                   Name       Definition             Parameters
--                                   ----       ----------             ----------
59880abc-166f-48fd-a96d-220f793c4f57 Translator Translate the text {{$ {[language, language], [sourcetext, sourcetext]}
59880abc-166f-48fd-a96d-220f793c4f57 Summarizer Summarize the text {{$ {[sourcetext, sourcetext]}
PS > Get-ChatFunction | Remove-ChatFunction
PS > Get-ChatFunction | Measure-Object | Select-Object Count
 
Count
-----
    0
 
In this example, all existing chat functions are enumerated by the Get-ChatFunction command. After this, Remove-ChatFunction is invoked with the output of Get-ChatFunction as input to its pipeline -- this deletes all of the previously enmerated functions, leaving no chat functions. This can be seen by the last command executed, which now returns a count of 0 for chat functions returned by the Get-ChatFunction command; prior to the use of Remove-ChatFunction, it had returned two such functions.
```

## PARAMETERS

### -Id
The Id of the property of the chat function to delete.
All chat functions have an Id property, so this parameter can be used to remove any chat function, and is also supported from the pipeline.

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
The name of the chat function to delete.
This can only be used of the function was created with a name.

```yaml
Type: String
Parameter Sets: name
Aliases:

Required: True
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

### None.
## NOTES

## RELATED LINKS

[New-ChatFunction
Get-ChatFunction
Invoke-ChatFunction
New-ChatScriptBlock]()

