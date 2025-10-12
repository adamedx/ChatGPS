---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Clear-ChatAgentState

## SYNOPSIS
Clears potentially orphaned system state managed by the shell agent removing sensitive data and freeing system resources.

## SYNTAX

```
Clear-ChatAgentState [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Clear-ChatAgent removes state created by Start-ChatAgent.
Start-ChatAgent can create text logs of PowerShell session text output; it is normally removed by the use of Stop-ChatAgent, but if PowerShell is executed without executing Stop-ChatAgent, any such files will be orphaned.
These files may contain sensitive information since they can include any output the was entered into a terminal as well as the output returned by commands.
To ensure unneeded files are removed and no longer a risk to expose private information, use the Clear-ChatAgent command.

Note: You can use the Get-ChatSession command to see the location of such state including the transcript path by sending its output to Format-List.

## EXAMPLES

### EXAMPLE 1
```
Clear-ChatAgentState
```

This simple invocation clears any local files on the system related to the chat agent that may include logs of command history or terminal command output.

## PARAMETERS

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

[Start-ChatAgent
Stop-ChatAgent]()

