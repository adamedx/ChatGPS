---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Stop-ChatAgent

## SYNOPSIS
Stops the shell agent and removes its state.

## SYNTAX

```
Stop-ChatAgent [-Session <ChatSession>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Stop-ChatAgent stops the shell agent started by Start-ChatAgent.
It also removes any state associated with the agent such as transcripts of PowerShell session output that may contain private data.

## EXAMPLES

### EXAMPLE 1
```
Stop-ChatAgent
```

## PARAMETERS

### -Session
{{ Fill Session Description }}

```yaml
Type: ChatSession
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
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

[Start-ChatAgent
Add-ChatPlugin
Set-ChatAgentAccess]()

