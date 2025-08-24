---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Select-ChatSession

## SYNOPSIS
Sets the default 'current' session used by commands that interact with language models when the command does not explicitly specify a session.

## SYNTAX

### byname (Default)
```
Select-ChatSession [-SessionName] <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byid
```
Select-ChatSession -Id <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Select-ChatSession sets the default session for ChatGOS commands that interact with language models.
Such commands require a session, an object created by the Connect-ChatSession either explicitly or indirectly through session configuration in ChatGPS settings.
The first such session created becomes the current setting if configuration does not specify the initial current session.
To change the current session, use the Select-ChatSession command with a session's id or name.
The list of sessions to choose from can be obtained by the Get-ChatSession command, and an arbitrary number of additional settings can be created by the Connect-ChatSession command.

Note that by default when the Connect-ChatSession command is invoked successfully, the newly created session becomes the current session, so it is not necessary to use Select-ChatSession to immediately start using a newly created session.
Select-ChatSession is most useful for switching between existing sessions.

Commands that interact with the language model will also have a parameter that allows specification of a session other than the current session, so it is not necesarry to use Select-ChatSession to set the correct session before every command.
However, particularly with interactive use of ChatGPS commands that will operate against the same language model and conversation context (the most common case), it is convenient not to have to repeatedly specify the session
parameter for every command invocation by relying on the current session managed by the Select-ChatSession command.

In the case of PowerShell functions bound to ChatGPS chat functions through the New-ChatScriptBlock command, Select-ChatSession is essential because such commands do interact with the language model, but they do not usually have a session parameter, so the only way to ensure they are operating against the correct session is to use the Select-ChatSession command before executing them; there is no way to override the session for such commands, they can only use the current session.

## EXAMPLES

### EXAMPLE 1
```
Select-ChatSession CodingSession
```

This invocation set the current session to a session named 'CodingSession'.
Subsequent commands that interact with langauge models will use this session unless an override is specified for that particular command.

### EXAMPLE 2
```
$workSession | Select-ChatSession
PS > $newCode = Build-BashScriptFromLLM $nlScriptSpec
PS > if ( Validate-BashScriptWithLLM $nlScriptSpec $newCode ) {
    out-file ~/documents/get-network-config.sh
}
```

This example shows how two commands created with New-ChatScriptBlock, Build-BashScriptFromLLM and Validate-BashScriptWithlLM that interact with the LLM can use a specific session by setting the current session with Select-ChatSession before the other commands are invoked.

## PARAMETERS

### -SessionName
The name property of an existing session that should be set to the current session.
To see the names of existing sessions, use the Get-ChatSession command.
The name property is not required for a session, so for such sessions without a name, it cannot be selected with the SessionName parameter of this command.
Instead, use the Id parameter to supply the session's Id property, which is always present.

```yaml
Type: Object
Parameter Sets: byname
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
The identifier of the session that should become the current session.
Unlike the name property, the Id property of Session is always present, so the Id can always be used as the way to select the session.
Use the Get-ChatSession command to enumerate existing sessions and their Id properties required for this parameter.

```yaml
Type: Object
Parameter Sets: byid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

[Get-ChatSession
Connect-ChatSession
Remove-ChatSession]()

