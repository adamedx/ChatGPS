---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Remove-ChatPlugin

## SYNOPSIS
Removes a chat plugin associated with a session.

## SYNTAX

```
Remove-ChatPlugin [-Name] <String[]> [-SessionName <String>] [-Session <ChatSession>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Remove-ChatPlugin removes a specified chat plugin from a session, and this means the plugin's capabilities such as local computer system or user resource access will no longer be triggered by ChatGPS command interactions with language models in that session.
For more information regarding chat plugins and their capabilities, see the documentation for Add-ChatPlugin.

Note that Remove-ChatPlugin does not remove the chat plugin from the list of plugins registered as available to be added to a session through the Add-ChatPlugin command; built-in plugins that are available by default with ChatGPS can never be unregistered, but custom plugins registered using the Register-ChatPlugin command can be removed from the list of available plugins using the Unregister-ChatPlugin commmand.

If so desired, another instance of the same plugin could be restored to the session at a later time through the Add-ChatPlugin command.

By default, Remove-ChatPlugin removes plugins from the current session; specify the SessionName or Session parameters to remove the plugin from a session other than the current session.

## EXAMPLES

### EXAMPLE 1
```
Remove-ChatPlugin TimePlugin
```

In this example, the TimePlugin plugin is removed from the current session.

### EXAMPLE 2
```
Get-ChatPlugin | Remove-ChatPlugin
```

In this example, all plugins are removed from the current session.

## PARAMETERS

### -Name
The name of the chat plugin to remove.
For a list of plugins that can be removed from the session, use the Get-ChatPlugin command targeting the appropriate session.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SessionName
The name property of an existing session from which the specified plugin should be removed.
If neither this parameter nor the Session parameter are specified, the plugin will be removed from the current session.

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

### -Session
The session object (as returned by commands such as Get-ChatSession) ffrom which the plugin should be removed.
If neither this nor the SessionName parameter are specified then the plugin will be removed from the current session.

```yaml
Type: ChatSession
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

[Add-ChatPlugin
Get-ChatPlugin
Connect-ChatSession
Register-ChatPlugin
Unregister-ChatPlugin]()

