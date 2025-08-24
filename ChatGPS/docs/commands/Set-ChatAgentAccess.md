---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Set-ChatAgentAccess

## SYNOPSIS
Configures a chat session to allow or disallow interactions between language models and chat plugins that enable language model interactions with user accessible resources including the local computer system and applications.

## SYNTAX

```
Set-ChatAgentAccess [-Allowed] [-Session <ChatSession>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Set-ChatAgentAccess configures the AllowAgentAccess property of a session that is originally configured at session creation time (e.g.
through the Connect-ChatSession command or configuration settings application).
The boolean value defaults to false, and it controls whether chat plugins are invoked during interactions by ChatGPS commands such as Send-ChatMessage with the session's language model.

By default, sessions do not invoke plugins at all, even when chat plugins have been configured for the session via configuration, the Connect-ChatSession command, or dynamically through the Add-ChatPlugin command.
This means that language model interactions with ChatGPS are simply exchanges of messages; there are no side effects to the message exchange, so a language model response cannot cause local files to be read or written, data to be sent from the computer to some destination, etc.

However when the AllowAgentAccess property is set to true through the Set-ChatAgentAccess command or other mechanisms, any plugins configured for the session may now be invoked.
This occurs when a ChatGPS command sends a message to the language model indicating the presence of the session's plugins, and the language model response includes instructions for the original sender, ChatGPS, to invoke the plugins.
ChatGPS will do so, and this allows the language model to obtain information from the local computer or services to which the user has access.
It can also allow updates to the local computer or other resources such as services that the user or computer running ChatGPS can access.
This can allow language models to serve as "agents" acting on your behalf, but is also risky as the language model may malfunction, may not be trustworthy, and is ultimately unaccountable legally or philosophically for the actions initiated through the plugins for which it provided instructions.

The Set-ChatAgentAccess command is useful for situations when you temporarily need to utilize plugins during an interaction (perhaps your language model conversation requires the model to be aware of recent internet search results, so you want to use the Bing search engine plugin), but as a security measure you want to disable the plugin access once it is no longer needed without the necessity of ending a potentially valuable conversation with the language model that was advanced due to earlier plugin access.
Set-ChatAgentAccess allows you to enable and disable plugin access as needed without starting a completely new chat session and losing useful ongoing language model conversations.

Note that the Get-ChatSession command can be used to determine the current value of the AllowAgentAccess property since this property is exposed exposed as a property in the output of Get-ChatSession.

## EXAMPLES

### EXAMPLE 1
```
Set-ChatAgentAccess -Allowed
```

This command sets AllowAgentAccess property to true, allowing any plugins configured for the session to be invoked as part of language model interactions.

### EXAMPLE 2
```
Get-ChatSetting -Current | Select Name, AllowAgentAccess, Plugins
 
Name       AllowAgentAccess Plugins
----       ---------------- -------
azure-int              True {Bing, FileIOPlugin, TimePlugin}
 
PS > Set-ChatAgentAccess -Allowed:$false
 
PS > Get-ChatSetting -Current | Select Name, AllowAgentAccess, Plugins
 
Name       AllowAgentAccess Plugins
----       ---------------- -------
azure-int             False {Bing, FileIOPlugin, TimePlugin}
```

This example shows how the Set-ChatAgentAccess command can disable the AllowAgentAccess capability by specifying the Allowed parameter with the explicit boolean specification syntax '-Allowed:\<booleanvalue\>' to set the property to false.
Before the Set-ChatAgentAccess command is executed, the Get-ChatSession command is used to examine the current session and show that the AllowAgentAccess property is set to true.
After Set-ChatAgentAccess is executed to disable the capability, the same Get-ChatSession command is repeated, and the property now shown as false.
The Bing, FileIOPlugin, and TimePlugin plugins remain configured for the session, but because AllowAgentAccess is now false, they will not be invoked, and it's as if they had never been added.

## PARAMETERS

### -Allowed
Specify the Allowed parameter to set the session's AllowAgentAccess property to true, allowing any chat plugins configured for the session to be invoked using instructions from the language model during its interactions intiated by ChatGPS commands such as Send-ChatMessage or Invoke-ChatFunction.
By setting this parameter, all of the user and local computers accessible by configured plugins can be controlled by the language model's instructions, so this setting should only be used when the provenance of the model and its quality is highly trusted and the plugins themselves expose only the necessary capabilities required by the user at the time of the interaction with the model.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session
The session for which to configure the AllowAgentAccess property.
If this parameter is not specified, the operation occurs for the current session, otherwise it is executed on the session specified by this parameter.

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

[Connect-ChatSession
Add-ChatPlugin
Get-ChatSession]()

