---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Get-ChatLog

## SYNOPSIS
Gets the conversation history of messages for a chat session interaction with a language model.

## SYNTAX

### byname (Default)
```
Get-ChatLog [[-SessionName] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byid
```
Get-ChatLog -Id <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-ChatLog returns the sequence of natural language messages ever sent and received by ChatGPS commands to the language model along with each resulting response from the model.
Commands such as Send-ChatMessage or Start-ChatShell are used to send messages to the language model in the context of a session where the latest message is interpreted by the language model using the context of previously sent messages in the session, just as in a two-person human conversation.
This log of all messages always grows with each request and response; it is distinct from the current conversation history sent to the language model, which has model-specific size limits and must be compressed through truncation, summarization, or other strategies once it exceeds this context windows limit.
Get-ChatLog returns all messages ever sent and received regardless of the model's limits.

This command can be contrasted with Get-ChatConversation, which returns only the session conversation uhistory used in the latest interaction with the model on that session.
Typically in the early stages of a conversation the results returned by Get-ChatLog and Get-ChatConversation are identical, and only diverge once the conversation nears the model's size limit and the conversation context is compressed while the log continues to grow and reflect all messages.

The one way in which the log size can be reduced is to clear it using the Clear-ChatLog command.

The Get-ChatLog command would be useful in any user experience that intends to show the entire history of the conversation.

## EXAMPLES

### EXAMPLE 1
```
Get-ChatLog
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
7/2/2025 7:29:30 PM      User                  0 what is the latest version of Semantic Kernel?
7/2/2025 7:29:33 PM      Assistant          2536 The latest version of Semantic Kernel available on NuGet
                                                 is version 1.59.0. If you would like more details or
                                                 links to the releases, let me know!
7/2/2025 7:29:42 PM      User                  0 Thank you.
7/2/2025 7:29:43 PM      Assistant           781 You're welcome! If you have any more questions or need
                                                 further assistance, feel free to ask. Have a great day!
7/2/2025 7:30:29 PM      User                  0 when was this latest version released?
7/2/2025 7:30:32 PM      Assistant          3370 The latest version of Semantic Kernel, version 1.59.0,
                                                 was released on July 1, 2025.
```

In this example the sequence of messages sent by the User role via a command like Sent-ChatMessage with the response received from the Asssitant role are displayed in the order in which they occured.

### EXAMPLE 2
```
Get-ChatLog
 
PS > Get-ChatLog | Measure-Object | Select-Object Count
 
Count
-----
    6
PS > Get-ChatConversation | Measure-Object | Select-Object Count
 
Count
-----
    6
 
PS > Clear-ChatLog
 
PS > Get-ChatLog | Measure-Object | Select-Object Count
 
Count
-----
    0
PS > Get-ChatConveration
 
Count
-----
    0
```

This example shows that Get-ChatLog returns a record of all messages exchanged, and that Clear-ChatLog clears all messages in the log without impact messages in the current conversation history.

## PARAMETERS

### -SessionName
Optional name of an existing session created by Connect-ChatSession or the settings infrastructure for which the log should be retrieved.

```yaml
Type: Object
Parameter Sets: byname
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Optional session identifier of an existing session for which the log should be retrieved.

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

### The command returns a collection of messages that include information about the source role of the message (e.g. the 'User' via a command like Send-ChatMessage or the language model labeled as 'Assistant'). Thus the collection contains one entry for each message sent and one for each received. Duration for receiving a response to the message is also returned. The message collection is ordered temporally.
## NOTES

## RELATED LINKS

[Clear-ChatLog
Get-ChatConversation
Clear-ChatConversation
Connect-ChatSession
Select-ChatSession]()

