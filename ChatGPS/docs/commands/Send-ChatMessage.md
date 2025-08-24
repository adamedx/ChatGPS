---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Send-ChatMessage

## SYNOPSIS
Sends a message with conversation context to a language model and returns the response from the model.

## SYNTAX

```
Send-ChatMessage [-Message] <String> [-FunctionDefinition <String>] [-OutputFormat <String>]
 [-ReceiveBlock <ScriptBlock>] [-ReplyBlock <ScriptBlock>] [-MaxReplies <Int32>] [-Session <ChatSession>]
 [-AsJob] [-AllowAgentAccess] [-DisallowAgentAccess] [-RawOutput] [-NoOutput] [-NoReplyOutput] [-MessageSound]
 [-SoundPath <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Send-ChatMessage sends a specified message to the language model for and receives a response which is returned as the command's output.
While Send-ChatMessage is easy to use in its own right as a way to request answers to straightforward questions, it is particularly useful as a tool for automated scripts to access language models.

Alternatively, the Start-ChatShell command provides an ongoing interactive chat loop interface for extended conversations purely using natural language without the need to adhere to PowerShell command syntax; consult the Start-ChatShell documentation for more details.

The message sent to the language model by Send-ChatMessage is added to the chat session's conversation history as the latest message, and then response from the language model is added after it.
The language model's response takes into account previous conversation history.
Messages sent by the user as well as those returned by the model will typically use natural language.
The capability to return responses to user-specified messages is commonly known as "chat completions" as the model is simply predicting or "completing" the chat history with the most likely response based on its trained understanding of the way in which human conversations typically proceed.

Thus messages are communicated within the context of a chat session created by the Connect-ChatSession command.
Sessions not only define the location of the model and associated access information such as credentials, but also maintain the conversation history of messages sent to the model and received from it.
For more information about chat sessions, see the Connect-ChatSession command.

To reset conversation context used by Send-ChatMessage, i.e.
to start a new converation, use the Clear-ChatConversation command.

Send-ChatMessage provides facilities for formatting the response returned by the command.
It also allows the optional specification of script blocks to process messages before they are sent to the model, and also to process responses received from the model.
The ReplyBlock feature also allows the command to automatically send a new request to the model as a reply to the model's response.

## EXAMPLES

### EXAMPLE 1
```
Send-ChatMessage Hello
```

Received                 Response
--------                 --------
3/11/2025 10:10:16 PM    Hello!
How can I assist you today?

Send-ChatMessage is used to send a greeting message of "Hello", and an appropriate response is returned by the language model.
The time of the response as well as its content is part of the output of Send-ChatMessage and both are rendered by default to the console.

### EXAMPLE 2
```
Get-Content ~/myprompts.txt | Send-ChatMessage
 
Received                 Response
--------                 --------
7/11/2025 4:15:41 PM     Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
7/11/2025 4:15:42 PM     $params = @{
                             Parameter1 = 'Value1'
                             Parameter2 = 'Value2'
                             Parameter3 = 'Value3'
                         }
                         Some-Command @params
 
PS > Get-Content ~/myprompts.txt
 
Please generate PowerShell code that outputs the temperature of the CPU. Emit only code, no markdown formatting.
How do I implement splatting in Powershell?
```

In this example, a text file consistning of prompts delimited by newlines is piped to Send-ChatMessage -- each prompt in the file is processed and its output is emitted.
The invocation of Send-ChatMessage is followed by the invocatio of Get-Content against the prompt file so that the prompts it contained can be compared against the output of Send-ChatMessage.

### EXAMPLE 3
```
Get-Content ~/myprompts.txt | Send-ChatMessage -AsJob
 
Id     Name                 PSJobTypeName   State
--     ----                 -------------   -----
4      Send-ChatMessageJob2 ThreadJob       Completed
 
Get-Job SendChatMessageJob2 | Receive-Job -Wait
 
Received                 Response
--------                 --------
7/11/2025 4:15:41 PM     Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
7/11/2025 4:15:42 PM     $params = @{
                             Parameter1 = 'Value1'
                             Parameter2 = 'Value2'
                             Parameter3 = 'Value3'
                         }
                         Some-Command @params
```

This example is the same as the previous case, but the AsJob parameter is used to create a job.
Receive-Job is used to wait for the job to finish and return the output, which is identical to the default case where AsJob is not specified.

### EXAMPLE 4
```
Connect-ChatSession -SystemPromptId Terse -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini
PS > Send-ChatMessage 'What attribute do I use to define a specific set of values for the parameter of a Powershell function?'
 
Received                 Response
--------                 --------
7/17/2025 10:46:35 PM    Use the `[ValidateSet()]` attribute to define
                         a specific set of allowed values for a
                         PowerShell function parameter.
```

This example creates a new connection using the 'Terse" system prompt Id to get a more concise than is typical for this model, demonstrating that Send-ChatMessage is highly dependent on the chat session's system prompt and other settings.
To reduce the need to provide explicit instructions for each message sent with Send-ChatMessage it can be convenient to choose a specific system prompt to impact the session as a whole.

### EXAMPLE 5
```
Add-ChatPlugin FileIOPlugin
PS > Send-ChatMessage -AllowAgentAccess 'Summarize in one sentences the purpose of the following PowerShell code located at the path ./commands/Send-ChatMessage.ps1.'
 
Received                 Response
--------                 --------
7/25/2025 11:15:16 PM    The purpose of the PowerShell code located at
                         `./commands/Send-ChatMessage.ps1`
                         is to send a specified message to a language
                         model within a chat session, receive the model's
                         response, and return it as output, all while
                         maintaining conversation context and allowing for
                         automated scripts to interact with the model.
```

This example shows how to enable agent access, which in this case allows the FileIOPlugin to be used to access a file as directed by the message sent by Send-ChatMessage.
The AllowAgentAccess parameter is specified to ensure that plugins are allowed, even if the session has not been configured to set the AllowAgentAccess property to true using Set-ChatAgentAccess.

### EXAMPLE 6
```
Send-ChatMessage 'Can you generate concise Python code to issue an HTTP GET request?' | Select-Object  Content
 
Content
-------
Sure! Here's a concise version of the Python code to issue an HTTP GET request:ª
 
```python
import requests
 
response = requests.get('https://api.example.com/data')
print(response.json() if response.status_code == 200 else response.status_code)
```
  PS > Send-ChatMessage 'Can you show Python code that will issue an HTTP GET request?' | Select-Object Content
 
Content
-------
import requests
 
response = requests.get('https://api.example.com/data')
print(response.json() if response.status_code == 200 else response.status_code)
```

In this example multiple chat message are exchanged; notice that subsequent chat messages assume the previous requests and responses as context, so the user can refine previous requests to get a better answer as in this case, and in general interact through "human-like" exchanges of dialogue.
When you do need to clear the context and start a conversation from the beginning, use the Clear-ChatConversation command.

### EXAMPLE 7
```
$response = Send-ChatMessage "Can you return all the scores of yesterday's professional basketball games as JSON? The structure should be an array of game element that represents the score of the game. The game element should have a two keys, one called Team1, the other called Team2, and the value of each key should be the name of each of the teams in a game. There should be two other keys in the game element, one called Score1 the other called Score2, and the value of each key should be the score of each team in that game. Only return JSON, do not return markdown or explanatory text."
 
PS > $response | Select-Object -ExpandProperty Response | ConvertFrom-Json
 
Team1           Team2                 Score1 Score2
-----           -----                 ------ ------
Orlando         California               115    121
Chicago         Los Angeles              107    108
Miami           Boston                   116    123
Brooklyn        New York                 112    110
Denver          Phoenix                  123    120
Milwaukee       Toronto                  121    113
```

This example demonstrates how to use the output of Send-ChatMessage with other commands for additional processing.
In this case a more complex prompt was supplied.
The example assumes that a plugin such as Bing or Google was added to the session with the Add-ChatPlugin command, and the AllowAgentAccess property of the session was set to true.
The prompt supplied to Send-ChatMessage instructed the model to use web search to find the scores of games and represent them as JSON.
The Content property of the output of Send-ChatMessage is then piped to Convert-FromJson which is able to successfully deserialize the JSON, and a well-formatted result of the scores is presented to the terminal.

### EXAMPLE 8
```
> $logPath}
PS > Get-Content ~/myprompts.txt | Send-ChatMessage -ReceiveBlock $logger
PS > Get-Content ~/scrapbook.csv | ConvertFrom-Csv | Format-Table
 
Role      Content
----      -------
User      How do I redirect standard error in Powershell?
Assistant In PowerShell, redirect standard error using `2>`.Example:  ```powershellcommand 2> error.txt```This sends the...
User      How do I implement splatting in Powershell?
Assistant In PowerShell, implement splatting by using `@` with a hashtable (for named parameters) or array (for position...
```

This shows how to to define a script block that can be used to log responses (in this case both the original request and response).
The script block takes a single parameter that is the response, and in this case immediately emits it since the output of the script block is now what will be the output of the command.
It then does additional work to convert the original request and output line to csv, allowing a header if the target csv file doesn't exist.
Finally it appends the csv lines (prepended with a header line if the file doesn't yet exist).
So once the contents of a text file are piped to Send-ChatMessage which processes one prompt per line of the file, a final Get-Content is used to access the log and convert it from CSV, resulting in formatted display of the log to the terminal.

### EXAMPLE 9
```
Send-ChatMessage "Can you show me powershell code that for a given file will list output its file version? Only output PowerShell code since I intend to execute exactly what you respond with." -ReplyBlock {param($response, $userPrompt) if ( $response.Trim().StartsWith('```') ) { "Please try again -- you included markdown, you should only generate output that PowerShell can execute" } }
 
Received                 Response
--------                 --------
7/19/2025 6:57:56 PM     ```powershell
                         $filePath = "C:\path\to\your\file.exe"
                         $fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
                         $fileVersionInfo.FileVersion
                         ```
7/19/2025 6:57:56 PM     Please try again -- you included markdown, you should only generate output that PowerShell
                         can execute
7/19/2025 6:57:57 PM     $filePath = "C:\path\to\your\file.exe"
                         $fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
                         $fileVersionInfo.FileVersion
```

In this example, the ReplyBlock feature is used as a way to send additional requests or "replies" to the language model after receiving a response, in this case to validate the response and ask the model to retry the original request based on feedback about its first response.
If no output is returned by ReplyBlock, then no additional request is sent to the model and Send-ChatMessage terminates.
If there is any output, that output is sent to the model as if the user had sent it; it is added to the conversation history as another request from the user.
When the model responds to that request, the script block specified by ReplyBlock is invoked again unless the number of replies has exceeded the value of the MaxReplies parameter, in which case the command will terminate.
If MaxReplies is not specified, then by default the script block is invoked only once as in this example, where it was used to correct the model's output so that it did not contain markdown but only valid PowerShell code.

## PARAMETERS

### -Message
The message to send to the language model.
This can be natural language, or a programming language, or semi-structured data, or really any text contextualized by the chat session's system prompt.
The language model will return a response based on this message as well as the previous conversation history.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FunctionDefinition
The FunctionDefinition parameter allows for an optional natural language function to be applied to the message before it is sent to the model.
The function definition must have a parameter named "input" which receives the value of the Message parameter.
Note that invocation of the function will involve communication with the language model.
For more information on how to define a function, see the New-ChatFunction command.

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

### -OutputFormat
Specifies formatting that should be applied to the response before it is returned as the result of the command.
The default value of "None" returns the response as-is.
A value of Markdown will result the Show-Markdown comand being applied to the output, and PowerShellEscaped replaces the escaped version of the escape character, i.e.
'\`e\` with the unescaped value.

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

### -ReceiveBlock
Specify a script block for ReceiveBlock to process the response received from the model.
The first parameter of the script block is the model's response, and the script block can then return a result based on the response.
The second parameter is a response object with properties including the time of the response, and the third parameter is the user's original prompt.
It is not required for the scriptblock to have all three parameters or to use them all.
Possible uses include formatting the response or writing it to a log file.
Note that ReceiveBlock can be specified at the session level with Connect-ChatSession, and if it is specified with Send-ChatMessage then both script blocks will be executed, first the block at the session level and then the block specified to Send-ChatMessage.
See the ReceiveBlock parameter of Connect-ChatSession.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReplyBlock
Specify a script block for ReplyBlock that, like ReceiveBlock, receives a response from the model after a response is received, and unlike ReceiveBlock, a non-null output from ReplyBlock is sent to the model as if it had been sent by the user.
The first parameter of the script is the response from the model; the second is the prompt from which this message originated.
If the script block returns output, that output will be sent to the model as an additional user request that is part of the converation history, but if there is not output, the command will terminate and return whatever output would have been returned had the script block not executed.
This can be used to validate the response and then reply to the model with feedback to try again with additional context such as an error detected in the response, or to otherwise iterate on the model's response.
By default, ReplyBlock will be executed only once per invocation of Send-ChatResponse, but the MaxReplies parameter can be used to allow more than one reply (e.g.
multiple retries / refinements).

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxReplies
MaxReplies is used to control the number of times the script in ReplyBlock will be executed during the current invocation of Send-ChatMessage.
This can be used to limit the number of times ReplyBlock causes additional requests to the model, e.g.
it may ask the model to retry the original request or perform some new request, and MaxReplies allows customization of the number of times such automated replies are allowed.
By default, MaxReplies is 1, so ReplyBlock will be invoked only once, but this can be extended to allow more lengthy response / feedback loops with the model.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session
Specifies the chat session through which the message will be sent.
By default, the current session is used.

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

### -AsJob
Specifies that the command should be executed asynchronously as a job; this is useful when the interaction is expected to be slow due to significant token processing, inference complexity, or slow inferencing (e.g.
inferencing with only CPU and no GPU).
Instead of returning the results of the language model interaction, the command returns a job that can be managed using standard job commands like Get-Job, Wait-Job, and Receive-Job.
Use Receive-Job to obtain the results that would normally be returned without AsJob.

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

### -AllowAgentAccess
Specify AllowAgentAccess to override the session's AllowAgentAccess value to set it to true such that plugins can be used during command invocation.
This parameter only has an impact when the chat session's AllowAgentAccess value is false.
For more information about plugins and the AllowAgentAccess setting, see the Set-ChatAgentAccess.

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

### -DisallowAgentAccess
Specify DisallowAgentAccess to override the session's AllowAgentAccess value to set it to false such that plugins cannot be used during command invocation.
This parameter only has an impact when the chat session's AllowAgentAccess value is true.
For more information about plugins and the AllowAgentAccess setting, see the Set-ChatAgentAccess.

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

### -RawOutput
Specify RawOutput so that Send-ChatMessage sends only the verbatim output from the language model.
By default, the output is in the form of message objects which include the model's response as a field.

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

### -NoOutput
Specify NoOutput to prevent output from being emitted by the command; by default, the response from the language model is output.
This is useful if you simply want to capture the model's response in the session conversation history, but don't need to see or process the result.

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

### -NoReplyOutput
When ReplyBlock is specified, it is normally emitted as output so that output reflects conversation history since Send-ChatMessage was invoked.
To disable this and only show responses from the model, specify this parameter.

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

### -MessageSound
Specify this parameter so that a sound is played when a response is received from the language model.

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

### -SoundPath
When MessageSound is true, SoundPath provides a path to the sound, e.g.
a wave file or other sound file, to be played audibly when a message is received.

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

### When the AsJob parameter is not specivied, the command returns a message object that contains the response from the language model. The message object contains specific properties for the message text, the time at which the message was received, the sender of the message, etc. If the RawOutput options is specified however then instead of an object, only the message text is emitted. If the AsJob parameter is specified, a job object is returned that can be managed with PowerShell's standard Wait-Job, Get-Job, Remove-Job, and Receive-Job commands.
## NOTES

## RELATED LINKS

[Connect-ChatSession
Start-ChatShell                                                                                                                                             Clear-ChatConversation
Add-ChatPlugin]()

