---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Get-ChatSession

## SYNOPSIS
Gets information about currently defined chat sessions created by Connect-ChatSession or ChatGPS settings configuration.

## SYNTAX

### byname (Default)
```
Get-ChatSession [[-SessionName] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byid
```
Get-ChatSession -Id <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### current
```
Get-ChatSession [-Current] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-ChatSession returns a collection of chat session objects required for ChatGPS commands to interact with language models.
For more information on chat sessions, see the documentation for the Connect-ChatSession command.

By default, the Get-ChatSession returns information about all sessions.
Additional optional parameters may be used to return just a particular session of interest.

In addition to providing information about the session's language model's location and credentials, the session's optional user-specified friendly name, plugins, and latest chat conversation history message count, the command provices an "Info" column similar to that for file system commands like the POSIX or PowerShell 'ls' command that offers compressed status information.
The Info column is itself composed of four characters, with each of these characters having the following meaning from the leftmost to the right most character:

1.
AllowAgentAccess: The first column contains a '+' character if the session's AllowAgentAccess setting is set to true, and empty if it is false.
The setting, which can be configured at session creation time via Connect-ChatSession or changed at any time with the Set-ChatAgentAccess command, controls whether chat plugins may be invoked during language model interactions to allow the language model to access information / make changes  to / from the local system or user accessible resources.
2.
Local / Remote: The second column contains the character 'r' if the model is a remote model hosted outside of the local computer accessed via a transport such as HTTP (e.g.
through some REST API).
If the model exists on the local computer itself, then the value is 'l'.
3.
Connected status: The third column represents the status of validation of communications with the language model.
If a ChatGPS command has successfully interacted with the model (including test interactions initiated by the Connect-ChatSession) then the value is set to 'c' for "connected." If this is not the case, including cases where a remote model is being accessed via an authenticated API an authentication or authorization failed, then the value is 'd' for "disconnected" when the model is remote, or "-" when the model is local.
4.
Session status: The session status in the fourth column describes the state of the active conversation in the session.
A value of 's' means the conversation has been started, a value of 'x' means it has been started but that ongoing conversation contxt sent to the model for each subsequent chat message from the user / application is now an approximation of the full conversation history rather than the full history.
A value of '-' indicates that the conversation has not started, i.e.
it is "empty."

Additionally, between the first two columns of the default output format (the "Info" and "Name" columns), there is a "\>" character for the row which contains the current session, making that session easy to identify.

## EXAMPLES

### EXAMPLE 1
```
Get-ChatSession
 
Info   Name         Model                Provider    Count
----   ----         -----                --------    -----
+rd-   az-4.1-mini  gpt-4.1-mini         AzureOpenAI 1
 rcs   GPT4omini    gpt-4o-mini          OpenAI      7
+rdx > azure-int    gpt-4o-mini          AzureOpenAI 28
 rd-   gemini-20    gemini-2.0-flash-001 Google      1
 l--   llama3       llama3:latest        Ollama      1
 l-s   phi35local   phi-3.5              LocalOnnx   3
```

In this example, Get-ChatSession is invoked with no parameters, and all defined models are emitted.
The third row contains the "\>" character indicating that that session is the current session.

### EXAMPLE 2
```
Get-ChatSession -Current | Format-List
 
Id                     : 9d39b324-f41a-4282-991f-f4e1bac0a46d
Name                   : azure-int
Provider               : AzureOpenAI
IsRemote               : True
ApiEndpoint            : https://ryu-openai-2025-01.openai.azure.com/
AllowInteractiveSignin : False
AccessValidated        : False
AllowAgentAccess       : True
TokenLimit             : 16384
ModelIdentifier        : gpt-4o-mini
DeploymentName         : gpt-4o-mini
TotalMessageCount      : 28
CurrentMessageCount    : 21
HistoryContextLimit    : -1
```

In this example, the Current parameter is specified to Get-ChatSession so that only the current session is emitted, and the result is piped to Format-List to provide a detailed look at the properties of the session.
The leftmost '+' character indicates that the LLM is allowed to act as an "agent" in accessing chat plugins that enable the language model to interact with the resources exposed by the plugins.

## PARAMETERS

### -SessionName
The optional name property of an existing session for which information should be returned.
The name property is not required for a session, so for such sessions without a name, it cannot be selected with the SessionName parameter of this command.
Instead, use the Id parameter to supply the session's Id property, which is always present.

```yaml
Type: Object
Parameter Sets: byname
Aliases: Name

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
The optional identifier of the session for which information should be returned.
Unlike the name property, the Id property of Session is always present, so the Id can always be used as the way to select the session.
Use the Get-ChatSession command with no parameters to enumerate existing sessions and their Id properties required for this parameter.

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

### -Current
This optional parameter specifies that only information for the current session should be returned.
The current session is the session used by default for commands that interact with language models such as Send-ChatMessage, Start-ChatShell, or Invoke-ChatFunction.
For more information about the current session, see the Select-ChatSession command.

```yaml
Type: SwitchParameter
Parameter Sets: current
Aliases:

Required: True
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

### Detailed information about the specified defined sessions, including all information used to create the session other than credentials as well as state information about the session's connectivity to remote models and the session's conversation history.
## NOTES

## RELATED LINKS

[Connect-ChatSession
Select-ChatSession
Set-ChatAgentAccess
Remove-ChatSession
Save-ChatSessionSetting
Get-ChatHistory
Get-ChatLog]()

