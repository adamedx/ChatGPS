---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Start-ChatShell

## SYNOPSIS
Sends a message with conversation context to a language model and returns the response from the model.

## SYNTAX

### chat (Default)
```
Start-ChatShell [[-InitialPrompt] <String>] [-OutputFormat <String>] [-PromptHint <ScriptBlock>]
 [-HideInitialPrompt] [-HideInitialResponse] [-HidePrompt] [-NoOutput] [-RawOutput] [-NoWelcome] [-ShowWelcome]
 [-ReceiveBlock <ScriptBlock>] [-UserReplyBlock <ScriptBlock>] [-MaxReplies <Int32>] [-AllowAgentAccess]
 [-DisallowAgentAccess] [-NoAutoConnect] [-MessageSound] [-AllowInitialReceiveBlock] [-SplashTitle <String>]
 [-SoundPath <String>] [-Session <ChatSession>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### functiondefinition
```
Start-ChatShell [[-InitialPrompt] <String>] [-FunctionDefinition <String>] [-OutputFormat <String>]
 [-PromptHint <ScriptBlock>] [-HideInitialPrompt] [-HideInitialResponse] [-HidePrompt] [-NoOutput] [-RawOutput]
 [-NoWelcome] [-ShowWelcome] [-ReceiveBlock <ScriptBlock>] [-UserReplyBlock <ScriptBlock>]
 [-MaxReplies <Int32>] [-AllowAgentAccess] [-DisallowAgentAccess] [-NoAutoConnect] [-MessageSound]
 [-AllowInitialReceiveBlock] [-SplashTitle <String>] [-SoundPath <String>] [-Session <ChatSession>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### functionname
```
Start-ChatShell [[-InitialPrompt] <String>] [-FunctionName <String>] [-OutputFormat <String>]
 [-PromptHint <ScriptBlock>] [-HideInitialPrompt] [-HideInitialResponse] [-HidePrompt] [-NoOutput] [-RawOutput]
 [-NoWelcome] [-ShowWelcome] [-ReceiveBlock <ScriptBlock>] [-UserReplyBlock <ScriptBlock>]
 [-MaxReplies <Int32>] [-AllowAgentAccess] [-DisallowAgentAccess] [-NoAutoConnect] [-MessageSound]
 [-AllowInitialReceiveBlock] [-SplashTitle <String>] [-SoundPath <String>] [-Session <ChatSession>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### functionid
```
Start-ChatShell [[-InitialPrompt] <String>] [-FunctionId <String>] [-OutputFormat <String>]
 [-PromptHint <ScriptBlock>] [-HideInitialPrompt] [-HideInitialResponse] [-HidePrompt] [-NoOutput] [-RawOutput]
 [-NoWelcome] [-ShowWelcome] [-ReceiveBlock <ScriptBlock>] [-UserReplyBlock <ScriptBlock>]
 [-MaxReplies <Int32>] [-AllowAgentAccess] [-DisallowAgentAccess] [-NoAutoConnect] [-MessageSound]
 [-AllowInitialReceiveBlock] [-SplashTitle <String>] [-SoundPath <String>] [-Session <ChatSession>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Start-ChatShell command provides an ongoing interactive chat loop interface, i.e.
a Read-Eval-Print-Loop (REPL) for extended conversations purely using natural language without the need to adhere to PowerShell command syntax.
It functions as an interactive implementation of Send-ChatMessage with an emphasis on continous natural language interactions with the language model.

Start-ChatShell presents the user with a prompt, and when the user enters a line of text in presonse, that text is sent to the model as if it had been sent by the Send-ChatMessage command.
Once a response is received, it is displayed to the user and then the user can enter additional text.

Thus Start-ChatShell provides an experience analogous to many "chatbots" that enable interactions with language models, treating the models as if they were humans rather than software.

In addition to natural language input, the REPL supports a small number of simple "shell commands" that allow basic interactions outside of natural language.
Shell commands are prefixed with a "." and must be the first non-whitespace character of any line of text entered by the user for the command to be executed correctly.

The '.exit' command ends the Start-ChatShell command (CTRL-C may also be used).
Use the '.help' command to list all of the shell commands, including '.history' to review previous messages in the chat and '.last' to see the last response again.

Start-ChatShell continues indefinitely until the user chooses to terminate the command by entering the '.exit' shell command.

Conversations conducted with Start-ChatShell occur in the context of a chat session, just as messsages from Send-ChatMessage and their replies do.
In fact, the same chat session can contain messages from both Send-ChatMessage and Start-ChatShell, and because of this, the user can freely exist Start-ChatShell and then use Send-ChatMessage where it will include the context from the messages exchanged in Start-ChatShell when interacting with the model, and on returning to Start-ChatShell the messages from Send-ChatMessage will also be part of the context in the REPL.
Both commands contribute to the same session which has a single conversation history shared by all commands, and this allows for changes in conversation mode as needed without the loss of context.

Note that the conversation settings of Connect-ChatSession influence the behavior of Start-ChatShell and Send-ChatMessage in the same way, including adherence to the system prompt and any receive blocks specified to the session.

Plugins added to the session impact conversations in Start-ChatShell just as they do Send-ChatMessage, so your conversation with the model can take advantage of plugins that access web search engines, the local file system, any custom plugin functionality you define with Register-ChatPlugin, etc.

To reset conversation context used by Start-ChatShell, the '.clearhistory' shell command can be used from Start-ChatShell, and it has the same impact as the Clear-ChatConversation command.
Alternatively, the Clear-ChatConversation command can be invoked explicitly.

## EXAMPLES

### EXAMPLE 1
```
Start-ChatShell
 
(morpheus) ChatGPS>: hello
 
Received                 Response
--------                 --------
2/9/2025 7:53:47 PM      Hello! How can I assist you today?
```

When executed with no arguments, the user is presented with a prompt and receives a typical response from the language model.

### EXAMPLE 2
```
chatgps
 
(ryu) ChatGPS>: Can you translate this Chinese text to English? 我要坐哪个火车去机场？
 
Received                 Response
--------                 --------
7/19/2025 10:08:04 PM    The translation of the Chinese text "我要坐哪个火车去机场？" to English
                         is "Which train should I take to the airport?"
 
(ryu) ChatGPS>: Thanks! Can you tell me if my grammar was correct in that last Chinese text I submitted?
 
7/19/2025 10:21:01 PM    Yes, your grammar in the Chinese text "我要坐哪个火车去机场？" is correct.
                         The structure is clear, and the sentence conveys the meaning accurately.
 
                         - "我要" means "I want to."
                         - "坐" means "take" (as in taking a train).
                         - "哪个" means "which."
                         - "火车" means "train."
                         - "去" means "to."
                         - "机场" means "airport."
 
                         Overall, it's a well-constructed question!
 
(ryu) ChatGPS>: Thank you, that was very helpful.
 
7/19/2025 10:21:30 PM    You're welcome! I'm glad you found it helpful. If you have any more
                         questions or need assistance with anything else, feel free to ask!
 
(ryu) ChatGPS>: .exit
```

PS \> chatgps
 
Received                 Response
--------                 --------
7/19/2025 10:21:30 PM    You're welcome!
I'm glad you found it helpful.
If you have any more
                         questions or need assistance with anything else, feel free to ask!
 
(ryu) ChatGPS\>:

This example uses the alias chatgps instead of Start-Shell.
The user and language model engage in a brief conversation about language translation.
The user exits the command with the '.exit' shell command and is returned to the PowerShell prompt.
The user re-invokes Start-ChatShell through the chatgps alias, and Start-Shell then displays the last message in the conversation so the user can re-engage.

### EXAMPLE 3
```
chatgps
 
░█▀▀░█░█░█▀█░▀█▀░█▀▀░█▀█░█▀▀
░█░░░█▀█░█▀█░░█░░█░█░█▀▀░▀▀█
░▀▀▀░▀░▀░▀░▀░░▀░░▀▀▀░▀░░░▀▀▀
 
Welcome to ChatGPS Shell 0.1.0!
 
Tuesday, July 15, 2025 10:42:46 PM
 
 * View configuration at ~/.chatgps/settings.json
 * Enter '.help' for a list of built-in shell commands
 
(ryu) ChatGPS>: .help
 
Shell commands must start with '.'; valid commands are:
 
- .clearhistory
- .exit
- .help
- .history
- .last
- .showconnection
 
(ryu) ChatGPS>: .help
```

In this example Start-Shell is started using its alias, and this is the first time Start-ChatShell has been invoked in this PowerShell session, so it shows a welcome message.
The user enters the '.help' shell command which shows a list of all the valid shell commands.
Note that the example text above contains an oddity where the shell commands listed above are prefixed with a '-' -- this is due to the fact that this very documentation is sourced in PowerShell comment help, and apparently a line starts with a '.' this can invalidate the comment help and the command will then have no documentation exposed in the Get-Help command.
So the '-' character is not part of the actual command functionality, just a mechanism to work around a limitation in PowerShell's command help implementation.
The '-' characters must not be removed from this documentation even though it is not part of the actual functionality unless a new mechanism is used for documentation.

### EXAMPLE 4
```
$encryptedBingApiKey = Get-AzKeyVaultSecret -VaultName BingVault -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > Add-ChatPlugin -PluginName Bing -ParameterNames apiKey -ParameterValues $encryptedBingApiKey
PS > Add-ChatPlugin -PluginName TimePlugin
PS > chatgps
(ryu) ChatGPS>: Can you tell me the latest PowerShell version released this year?
 
Received                 Response
--------                 --------
7/19/2025 11:59:43 PM    The latest PowerShell version released this year (2025) is PowerShell 7.5. The General
                         Availability (GA) of PowerShell 7.5 is expected in January or February 2025, and it
                         is built on top of .NET 9.0.301. There is also a preview version 7.6 available recently, but
                         7.5 is the stable release for this year.
 
(ryu) ChatGPS>: When was PowerShell 7.5 released?
 
7/20/2025 12:00:01 AM    PowerShell 7.5 became generally available (GA) in March 2025.
 
(ryu) ChatGPS>: What were its top three notable features?
 
7/20/2025 12:00:34 AM    The top three notable features of PowerShell 7.5 are:
 
                         1. **Integration with Windows Package Manager (winget):** PowerShell 7.5 includes native
                         support for managing packages using winget, allowing for streamlined software
                         installation, upgrade, and management directly from the PowerShell console.
 
                         2. **Improved Cross-Platform Support:** This version enhances compatibility and performance
                         across different operating systems, including  Windows, macOS, and various Linux
                         distributions, providing more consistent behavior and better tooling for cross-platform
                         scripting.
 
                         3. **Enhanced Predictive IntelliSense:** PowerShell 7.5 features advanced predictive
                         IntelliSense capabilities, offering smarter command and parameter suggestions based on
                         context and user history, which improves scripting efficiency and reduces errors.
 
                         If you want, I can provide more details or additional features included in PowerShell 7.5.
 
(ryu) ChatGPS>: can you tell me the command I can use to install it?
 
7/20/2025 12:01:59 AM    To install PowerShell 7.5 using the Windows Package Manager (winget), you can use the
                         following command in an elevated PowerShell or Command Prompt:
 
                         ```powershell
                         winget install --id Microsoft.PowerShell --version 7.5
                         ```
 
                         This command will download and install PowerShell 7.5 on your system. If you want to
                         install the latest available version regardless of the specific version number, you
                         can omit the `--version` parameter:
 
                         ```powershell
                         winget install --id Microsoft.PowerShell
                         ```
 
                         Let me know if you need guidance for installing PowerShell 7.5 on other operating
                         systems.
 
(ryu) ChatGPS>:
```

Here Start-ChatShell is invoked with the chatgps alias after the Bing web search and Time plugins have been configured for the session.
As a result, the subsequent conversation in Start-ChatShell includes web searches and time awareness for model interactions, and the user is able to engage the LLM to find new information as the conversation about PowerShell progresses.

### EXAMPLE 5
```
Send-ChatMessage 'Can you show a PowerShell script that enumerates all the PowerShell 7 processes?'
 
Received                 Response
--------                 --------
7/20/2025 6:51:21 AM     ```powershell
                         Get-Process pwsh
                         ```
PS > Start-ChatShell
 
Received                 Response
--------                 --------
7/20/2025 6:51:34 AM     ```powershell
                         Get-Process pwsh
                         ```
 
(ryu) ChatGPS>: can you modify it so that it lists them in order of process creation?
```

7/20/2025 6:52:30 AM     \`\`\`powershell
                         Get-Process pwsh | Sort-Object StartTime
                         \`\`\`
 
(ryu) ChatGPS\>: Thanks.
Can you also add a secondary ordering by memory utilization?
 
7/20/2025 6:52:56 AM     \`\`\`powershell
                         Get-Process pwsh | Sort-Object StartTime,
                         @{Expression='WorkingSet'; Descending=$true}
                         \`\`\`
 
(ryu) ChatGPS\>: .exit
 
PS \> Send-ChatMessage 'Can you provide that without any markdown formatting please, just PowerShell code?' | Select-Object -ExpandProperty Response | Out-File  ~/Get-PsInstances.ps1
PS \> Get-ChatConveration
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
7/16/2025 6:51:13 AM     User                  0 Can you show a  PowerShell script that enumerates all the
                                                 PowerShell 7 processes?
7/16/2025 6:51:21 AM     Assistant          7667 \`\`\`powershell
                                                 Get-Process pwsh
                                                 \`\`\`
7/16/2025 6:52:22 AM     User                  0 can you modify it so that it lists them in order of process
                                                 creation?
7/16/2025 6:52:30 AM     Assistant          7345 \`\`\`powershell
                                                 Get-Process pwsh | Sort-Object StartTime
                                                 \`\`\`
7/16/2025 6:52:56 AM     User                  0 Thanks.
Can you also add a secondary ordering by memory
                                                 utilization?
7/16/2025 6:52:56 AM     Assistant           761 \`\`\`powershell
                                                 Get-Process pwsh | Sort-Object StartTime,
                                                 @{Expression='WorkingSet'; Descending=$true}
                                                 \`\`\`
7/16/2025 6:54:30 AM     User                  0 Can you provide that without any markdown
                                                 formatting please, just PowerShell code?
7/16/2025 6:54:37 AM     Assistant          7531 Get-Process pwsh | Sort-Object StartTime,
                                                 @{Expression='WorkingSet'; Descending=$true}

This demonstrates that the use of Start-ChatShell and Send-ChatMessage may be interleaved, but the converation history across both is treated as a single continuous conversation when interacting with the language model, and this is reflected in the output of the Get-ChatConversation command which shows that both commands results are part of the chat session's ongoing context.

## PARAMETERS

### -InitialPrompt
Specify InitialPrompt so that the repl starts with a request to the language model, waiting for a response and displaying it before prompting the user and waiting for input.
By default, when Start-ChatShell is invoked it is waiting for input before sending any input to the language model.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionDefinition
Specifies a natural language function to be invoked whenever the user enters text.
It must have one argument named 'Input'; it is the user's text input.
The result of the function will be the response.
For more information on natural language functions, see the New-ChatFunction command documentation.

```yaml
Type: String
Parameter Sets: functiondefinition
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionName
Specifies the name of a natural language function that was created with New-ChatFunction.
It must conform to the requirements of FunctionDefinition.

```yaml
Type: String
Parameter Sets: functionname
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionId
Specifies the id of a natural language function that was created with New-ChatFunction.
It must conform to the requirements of FunctionDefinition.

```yaml
Type: String
Parameter Sets: functionid
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFormat
Specifies processing that should be applied to the response from the language model.
The default value of 'None' means no processing will be applied.
The value 'Markdown' means that the response will be interpreted as output and processed to produce markdown formatting using the Show-Markdown command.
The value 'PowerShellEscaped' will result in the response being evaluated as a PowerShell interpolated string so that expressions like '\`n' and '\`t' will be transformed into newline and tab characters respectively.

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

### -PromptHint
Specifies the text of the prompt displayed by the Start-ChatShell when waiting for user input.
Start-ChatShell has a default prompt, specify this parameter to override it.

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

### -HideInitialPrompt
By default, when InitialPrompt is specified, it is shown in the repl; specify this parameter to hide it.

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

### -HideInitialResponse
By default, the last response from the language model is shown shown when Start-ChatShell starts before asking for user input so the user has context on what the last response was in the conversation.
To hide this response, specify HideInitialResponse

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

### -HidePrompt
{{ Fill HidePrompt Description }}

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
By default, responses are echoed to the terminal.
Specify NoOutput so that the response will not be emitted to the terminal; it will still be present in the chat session history, and the response will still be processed by the script block from ReceiveBlock if it is specified.

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
By default, responses from the language model are output as structured formatted text.
To the response exactly as the language model returned it, specify RawOutput.

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

### -NoWelcome
By default, Start-ChatShell displays a welcome message the first time it is executed within a PowerShell session.
Specify this parameter so that no welcome message is displayed.

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

### -ShowWelcome
By default, Start-ChatShell will only show a welcome message the first time it is executed within a Powershell session, but to force the banner to be displayed specify the ShowWelcome parameter.

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

### -ReceiveBlock
Specify a script block for ReceiveBlock to process the response from the language model and alter the output that will be emitted by Start-ChatShell.
See the documentation for the ReceiveBlock parameter of the Send-ChatMessage command for details.

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

### -UserReplyBlock
Specify this parameter to send an automated reply to the language model based on its last response.
See the ReplyBlock parameter of the Send-ChatMessage command.

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
See the MaxReplies parameter of the Send-ChatMessage command which has the same semantics associated with UserReplyBlock.

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

### -AllowAgentAccess
{{ Fill AllowAgentAccess Description }}

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
{{ Fill DisallowAgentAccess Description }}

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

### -NoAutoConnect
By default, if there is no chat session connected by Connect-ChatSession Start-ChatShell will attempt to connect a default session.
Specify NoAutoConnect to prevent this; in that scenario, the command will fail and Connect-ChatSession will need to be invoked before retrying Start-ChatShell with this parameter enabled.

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
An experimental parameter that provides audible feedback to signal the arrival of a response from the language model.
The sound to be played is specified by the SoundPath parameter.

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

### -AllowInitialReceiveBlock
By default, when the initial response is emitted at the start of the command prior to user input, the script block specified by ReceiveBlock is not invoked.
To override this behavior and allow the receive block to be executed, specify AllowInitialReceiveBlock.

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

### -SplashTitle
When the welcome message is displayed by Start-Shell on first launch, it will include a "splash" banner.
By default the 'Normal' splash banner is shown when the value of SplashTitle is 'Normal'.
If it is 'Large', a larger splash is shown.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Normal
Accept pipeline input: False
Accept wildcard characters: False
```

### -SoundPath
An experimental feature that specifies the path for the sound to be played when MessageSound is specified.

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
Specifies the chat session on which to repl conversation will occur.

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

### The command itself has no output since any output from perceived by the user is actually written directly to the terminal's standard output rather than emitted to the PowerShell pipeline. To access language model responses via the pipeline, use the Send-ChatMessage command instead.
## NOTES

## RELATED LINKS

[Connect-ChatSession
Send-ChatMessage
Clear-ChatConversation
Add-ChatPlugin
Register-ChatPlugin]()

