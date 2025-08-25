---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Connect-ChatSession

## SYNOPSIS
Creates a new "chat" session between the user and a supported language model.
The model may be hosted locally or accessed remotely through a service provider.

## SYNTAX

### remoteaiservice
```
Connect-ChatSession [[-SystemPromptId] <String>] [-Name <String>] [-CustomSystemPrompt <String>]
 [-Provider <String>] [-ApiEndpoint <Uri>] [-DeploymentName <String>] [-ApiKey <String>] [-ReadApiKey]
 [-PlainTextApiKey] [-AllowInteractiveSignin] [-ModelIdentifier <String>] [-ServiceIdentifier <String>]
 [-TokenLimit <Int32>] [-TokenStrategy <String>] [-HistoryContextLimit <Int32>] [-SendBlock <ScriptBlock>]
 [-ReceiveBlock <ScriptBlock>] [-Plugins <String[]>] [-PluginParameters <Hashtable>] [-AllowAgentAccess]
 [-PassThru] [-NoSetCurrent] [-NoSave] [-NoConnect] [-Force] [-NoProxy] [-ForceProxy] [-LogDirectory <String>]
 [-LogLevel <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### localmodel
```
Connect-ChatSession [[-SystemPromptId] <String>] [-Name <String>] [-CustomSystemPrompt <String>]
 [-Provider <String>] [-AllowInteractiveSignin] -LocalModelPath <String> -ModelIdentifier <String>
 [-ServiceIdentifier <String>] [-TokenLimit <Int32>] [-TokenStrategy <String>] [-HistoryContextLimit <Int32>]
 [-SendBlock <ScriptBlock>] [-ReceiveBlock <ScriptBlock>] [-Plugins <String[]>] [-PluginParameters <Hashtable>]
 [-AllowAgentAccess] [-PassThru] [-NoSetCurrent] [-NoSave] [-NoConnect] [-Force] [-NoProxy] [-ForceProxy]
 [-LogDirectory <String>] [-LogLevel <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
A chat session is a communication channel between the user and an AI language model along with optional associated history of exchanged messages.
Commands such as Send-ChatMessage and Invoke-ChatFunction allow users to send messages to the language model using natural language or any other protocol supported by the language model; the language model will return responses as the output of these commands.
Before the communication commands may be used, a channel must be created by Create-ChatSession that may then be used by those commands to identify the location of the language model, provide credentials for models that require authentication, and to store the conversation history.

Connect-ChatSession supports both locally hosted models stored in the local device's file system, as well as cloud-hosted models.
Typically the former do not require authentication but the latter do.
The Provider parameter of the command is used to specify the kind of model, which in turn dictates whether the model is local or remote.

Connect-ChatSession implicitly maintains the concept of a "current" session, i.e.
simply by successfully executing the command, this special current session is set and the value of any previously set value for it is overwritten every time Connect-ChatSession is invoked.
To override this behavior and execute the command without setting the current session, use the NoSetCurrent parameter; instead of updating the current session, the new session will be returned as output of the command.
This allows the creation of multiple sessions without effecting the state of the "default" current session.
This is useful when automating interactions between multiple models, or simply using the same model but maintaining separate conversation histories.

By default, the session is created with one of several built-in system prompts that dictate the purpose and style of the conversation.
The command also supports providing a custom system prompt instead using the CustomSystemPrompt parameter.

## EXAMPLES

### EXAMPLE 1
```
Connect-ChatSession -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini # Use Login-AzAccount if this fails.
PS > Send-ChatMessage 'how do I find my mac address?'
```

In this example, a chat session is used to communicate with a model deployment called gpt-4o-mini provided by an Azure OpenAI service resource.
This will use the currently signed in credentials from Login-AzAccount by default and will fail if there is no such sign-in or if the signed in user does not have access to the specified model.
After the connection is created, the Send-ChatMessage command is used to send a message to the service and receive a response.
Note that it is not required to specify the Provider parameter since AzureOpenAI is the default when the ApiEndpint is specified.

### EXAMPLE 2
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

### EXAMPLE 3
```
$secretKey = Get-ChatEncryptedUnicodeKeyCredential
PS > Connect-ChatSession -Name TestSession -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini -ApiKey $secretKey
PS > Get-ChatSession
 
Id                                   Provider    Name        ModelIdentifier
--                                   --------    ----        ---------------
3cb205df-c4e2-4569-a2f3-8a059571ed23 AzureOpenAI TestSession gpt-4o-mini
```

In this example, a chat session is used to a remote model as in the previous example.
In this case, instead of the user's credentials, a symmetric key credential is provided by the ApiKey parameter.
The session is also given a name with the Name parameter.

### EXAMPLE 4
```
$secretKey = Get-ChatEncryptedUnicodeKeyCredential
PS > Connect-ChatSession -ModelIdentifier gpt-4o-mini -ApiKey $secretKey
PS > Get-ChatSession
 
Id                                   Provider    Name ModelIdentifier
--                                   --------    ---- ---------------
15934765-10c5-4caf-b477-180abd9d893d OpenAI           gpt-4o-mini
```

This example is similar to those above, but it uses the OpenAI provider instead -- since OpenAI does not currently require an ApiEndpoint parameter but does require an ApiKey parameter, use of the OpenAI provider is the default when only ApiKey is specified.
For OpenAI however the ModelIdentifier is required:

### EXAMPLE 5
```
Connect-Chatsession -LocalModelPath '/models/Phi-3.5-mini-instruct-onnx/gpu/gpu-int4-awq-block-128' -ModelIdentifier phi-3.5pu-int4-awq-block-128' -ModelIdentifier phi-3.5 -PassThru
 
Id                                   Provider    Name ModelIdentifier
--                                   --------    ---- ---------------
5825858e-5fe3-489e-a04f-aa4d494f91b5 LocalOnnx        phi-3.5
```

This example shows how to connect to a local phi-3.5 onnx model -- the Provider parameter may also be omitted in this case because currently when LocalModelPath is specified the LocalOnnx provider is implied (this will likely be impacted by a breaking change when additional local models are supported in the future).
The Get-ChatSession command which outputs the current session is used here to show that the values passed to Connect-ChatSesssion are in effect.
Lastly, the Start-ChatShell command is used to start an interactive conversation.

### EXAMPLE 6
```
Connect-Chatsession -LocalModelPath '/models/Phi-3.5-mini-instruct-onnx/gpu/gpu-int4-awq-block-128' -ModelIdentifier phi-3.5pu-int4-awq-block-128' -ModelIdentifier phi-3.5
 
PS > Start-ChatShell
 
(morpheus) ChatGPS>: hello
 
WARNING: Possible missing dependencies detected. Invoke the Install-ChatAddOn command to install missing dependencies and then retry this operation."
Start-ChatShell: Exception calling "GenerateMessage" with "2" argument(s): "Unable to initialize local Onnxmodel support. 
 
(morpheus) ChatGPS>: .exit
PS > Install-ChatAddOn
PS > Start-ChatShell
 
(morpheus) ChatGPS>: hello
 
Received                 Response
--------                 --------
12/30/2024 11:15:06 PM   Hello! I'm Phi, an AI language model here to assist you with any questions or tasks you have.
                         How can I help you today?
```

In this case, a connection was created to a local Onnx model.
Then when a prompt was submitted using the Start-ChatShell interactive loop, the command encountered an error caused by missing dependencies for Onnx.
These library dependencies are not installed with the ChatGPS module due to their size, but as the warning message suggests, running the Install-ChatAddOn command can address this by installing such missing components.
The user follows this suggestion and invokes Install-ChatAddOn, the retries submitting a prompt with Start-ChatShell and this successfully returns a response from the local model.

### EXAMPLE 7
```
Connect-ChatSession -Provider Anthropic -ModelIdentifier claude-sonnet-4-20250514 -ReadApiKey
ChatGPS: Enter secret key / password>: ****************************************************
PS > Send-ChatMessage Hello
 
Received                 Response
--------                 --------
8/16/2025 12:03:01 PM    Hello! It's nice to meet you. How are you doing today? Is there anything I can
                         help you with or any questions you'd like to ask? I'm here to assist with
                         information on a wide variety of topics.
```

In this example an Anthropic model is specified using the Provider parameter and the ReadApiKey parameter is used to securely specify the ApiKey as subsequent interactive input that is encrypted in memory and never echoed to the console.
After invocation of the command, Send-ChatMessage is used to elicit a response from the Anthropic model.

### EXAMPLE 8
```
Send-ChatMessage "Hello what is today's date?"
 
Received                 Response
--------                 --------
2/9/2025 4:02:03 PM      Hello! I don't have real-time capabilities, so I can't give you the current date. However,
                         you can easily check today's date on your device or calendar. Is there something specific
                         you'd like to know about a date or a particular event?
 
PS > Get-ChatConversation
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
2/9/2025 4:02:02 PM      User                  0 Hello what is today's date?
2/9/2025 4:02:03 PM      Assistant           950 Hello! I don't have real-time capabilities, so I can't give you
                                                 the current date. However, you can easily check today's date on your
                                                 device or calendar. Is there something specific you'd like to
                                                 know about a date or a particular event?
 
PS > Connect-ChatSession -SendBlock {param($text) "The time is: $([DateTime]::Now.ToString('F')). " + $text} -ApiEndpoint 'https://searcher-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini
 
PS > Send-ChatMessage "Hello what is today's date?"
 
Received                 Response
--------                 --------
2/9/2025 4:05:44 PM      Hello! Today's date is February 9, 2025. If you'd like to know more about that date, such as events that may occur or
                         historical significance, feel free to ask! To check your understanding: If today is February 9, 2025,
                         what would be the date one week later?
 
PS > Get-ChatConversation
 
Received                 Role       Elapsed (ms) Response
--------                 ----       ------------ --------
2/9/2025 4:05:43 PM      User                  0 The time is: Sunday, February 9, 2025 4:05:43 PM. Hello what is
                                                 today's date?
2/9/2025 4:05:44 PM      Assistant          1184 Hello! Today's date is February 9, 2025. If you'd like to know more
                                                 about that date, such as events that may occur or historical
                                                 significance, feel free to ask!
```

This example demonstrates how the SendBlock parameter can be used to modify user text before it is sent to the model.
In the first invocation
of Send-ChatMessage, the model responds to a question about the current time with an accurate answer that it does not know.
Get-ChatConversation
is used to show the session's current context of the conversation and it is clear that the text sent to the model is identical to the text provided to the Send-ChatMessage command.
However, Connect-ChatSession is used to create a new session and the SendBlock parameter is specified to the command with a script block that prepends
the user supplied text passed to the script block with the current time in an unambiguous format.
When the previous Send-ChatMessage command is
reissued, the model responds with a current date that is the same as the date shown in the conversation history.
Examination of the text sent to the model
shows that unlike in the previous attempt, the message sent from the user includes the current time due to the script block specified to SendBlock.
The script block is executed every time a message is sent to the model, so this shows one way in which the model can be made of some real time data during conversations.

### EXAMPLE 9
```
> ~/chatlog.csv} -ApiEndpoint 'https://searcher-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini
 
PS > 'Role', 'Message', 'Type', 'Duration', 'Timestamp' -join ',' | Set-Content ~/chatlog.csv
 
PS > Start-ChatShell
 
(morpheus) ChatGPS>: hello
 
Received                 Response
--------                 --------
2/9/2025 7:53:47 PM      Hello! How can I assist you today?
 
(morpheus) ChatGPS>: Can you tell me the year in which Brown v. Board of Education was decided?
 
2/9/2025 7:53:53 PM      Brown v. Board of Education was decided in the year 1954.
                         This landmark Supreme Court case declared racial segregation
                         in public schools unconstitutional.
                         Would you like to know more about the case or its impact on
                         civil rights?
 
(morpheus) ChatGPS>: In what year was integration of schools in Little Rock, Arkansas first attempted?
 
2/9/2025 7:53:59 PM      The integration of schools in Little Rock, Arkansas, was
                         first attempted in 1957. This event is famously associated
                         with the Little Rock Nine, a group of nine African American
                         students who enrolled in the previously all-white Central
                         High School.
 
(morpheus) ChatGPS>: .exit
 
PS > Get-Content ~/chatlog.csv | ConvertFrom-Csv | Format-Table -Property Timestamp, Role, Message
 
Timestamp                  Role      Message
---------                  ----      -------
2/9/2025 7:53:46 PM -08:00 User      hello
2/9/2025 7:53:47 PM -08:00 Assistant Hello! How can I assist you today?
2/9/2025 7:53:49 PM -08:00 User      Can you tell me the year in which Brown v. Board of Education was decided?
2/9/2025 7:53:53 PM -08:00 Assistant Brown v. Board of Education was decided in the year 1954. This landmark Supreme C…
2/9/2025 7:53:58 PM -08:00 User      In what year was integration of schools in Little Rock, Arkansas first attempted?
2/9/2025 7:53:59 PM -08:00 Assistant The integration of schools in Little Rock, Arkansas, was first attempted in 1957.…
```

This example uses the ReceiveBlock parameter to configure the session such that whenever a response is received from the model, the script block supplied to the ReciveBlock parameter will append the last message sent by the user as well as the response from the model to a comma-separated (csv) log file.
The script block contains code that reads the last two lines of history via the Get-ChatLog command and converts them to comma-delimited lines with ConvertTo-Csv.
A subsequent use of the Start-ChatShell command to conduct a short conversation is thus captured in the log file.
The ConvertFrom-Csv command along with standard PowerShell formatting commands can be used to view the log file as a table.

### EXAMPLE 10
```
Connect-ChatSession -ApiEndpoint 'https://devteam1-2024-12.openai.azure.com' -DeploymentName gpt-o1 -ApiKey $workKey
PS > $work2 = Connect-ChatSession -NoSetCurrent -ApiEndpoint 'https://devteam1-2024-12.openai.azure.com' -DeploymentName gpt-o1 -ApiKey $workKey
PS > $personal = Connect-ChatSession -NoSetCurrent -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini -ApiKey $personalKey
 
PS > $unreadMail = GetUnreadMail
PS > $emailSummary = Invoke-ChatFunction SummarizeMail $unreadMail -Session $work2 | Show-Markdown
 
PS > Start-ChatShell
 
(morpheus) ChatGPS>: please translate this Chinese text: '我应该乘坐什么火车去机场？'
 
Received                 Response
--------                 --------
12/30/2024 11:01:03 AM   The Chinese text '我应该乘坐什么火车去机场？' translates to "Which train should I take to the
                         airport?"
 
(morpheus) ChatGPS>: .exit
 
PS > $tahomaWeather = Invoke-WebRequest -UseBasicParsing 'https://forecast.weather.gov/MapClick.php?lat=46.9381&lon=-121.8623&unit=0&lg=english&FcstType=text&TextType=1' | select -ExpandProperty content
PS > Send-ChatMessage -Session $personal "Summarize the plaintext contained in this html content regarding the weather forecast for Mt. Rainier $tahomaWeather"
 
Received                 Response
--------                 --------
12/30/2024 11:04:22 AM   The weather forecast for the area 7 miles northwest of Mt. Rainier, WA, indicates the
                         following:
 
                         - **Tonight:** Partly cloudy with a low around 21°F and a light south southwest wind.
 
                         - **Tuesday:** A 30% chance of snow after 4 PM, partly sunny with a high near 28°F. Wind
                         chill values between 12°F and 22°F, with less than half an inch of new snow expected.
 
                         - **Tuesday Night:** Snow likely after 10 PM, with a low around 23°F. Wind chill values
                         between 10°F and 15°F, an 80% chance of precipitation, and 1 to 3 inches of new snow
                         accumulation possible.
 
                         - **New Year's Day (Wednesday):** Snow likely mainly before 4 PM, mostly cloudy, high near
                         29°F, and a 70% chance of precipitation with 1 to 2 inches of new snow expected.
 
PS > Start-ChatShell
 
Received                 Response
--------                 --------
12/30/2024 11:01:03 AM   The Chinese text '我应该乘坐什么火车去机场？' translates to "Which train should I take to the
                         airport?"
 
(morpheus) ChatGPS>: Thank you!
 
12/30/2024 11:07:42 AM   You're welcome! If you have any more questions or need help with anything else, feel free to
                         ask!
 
(morpheus) ChatGPS>:
```

In this example, a session is created as the curent session, and then NoSetCurrent option is used to create two new sessions without impacting the current session.
One of the latter two sessions uses the same model as the default which is suitable for professional usage, while the other connects to a personal model for non-work purposes.
The Start-ChatShell command is used with current session, then Send-ChatMessage and Invoke-ChatFunction commands are used with second and third sessions, and finally Start-ChatShell is used again and it is clear that the messages transmitted with the other sessions did not affect the conversation history of Start-ChatShell as it still shows the last response from the previous Start-ChatShell usage on that session as the latest response.

## PARAMETERS

### -SystemPromptId
An identifier corresponding to one of the built-in system prompts to be used for the session.
Values include PowerShell, General, PowerShellStrict, and Conversational.
The default value is PowerShell.
The PowerShell prompt focuses on natural language conversations about the PowerShell language and command-line tools and general programming language topics.
The General prompt is simply natural language conversation on any topic.
The Conversational prompt is similar to General with a focus on making the conversation more interesting.
The PowerShellStrict prompt expects natural language instructions for generating PowerShell code and will return only code; the code it returns as output to conversation commands can be directly executed by the PowerShell interpreter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Optional friendly name for the connection.
This is useful for switching between sessions using a friendly name view the Select-ChatSession command or in viewing the list of sessions with Get-ChatSession.

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

### -CustomSystemPrompt
Allows the user to specify a custom system prompt to steer converation and response output instead of using one of the prompts specified by the SystemPromptId parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Prompt

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Provider
Specifies the language model provider.
Currently supported values are LocalOnnx for Onnx (https://onnx.ai/) models hosted on the local file system, or AzureOpenAI for models accessed through the Azure OpenAI Service (https://azure.microsoft.com/en-us/products/ai-services/openai-service).
The default value is currently based on the presence of other parameters, though that may change as more providers are added that use the same parameter patterns.
To be sure that the correct provider is used, specify this parameter explicitly.
Note that LocalOnnx currently requires that this command is invoked on the Windows operating system using the x64 or arm64 processor architectures.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ApiEndpoint
For remotely hosted models, the API URI that enables access to the model.

```yaml
Type: Uri
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeploymentName
For remotely hosted models some services may require this as an additional parameter to identify the specific model to use.
This parameter usually only applies to remote models.

```yaml
Type: String
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ApiKey
Some remotely hosted models that require authentication may support a symmetric key that can be specified through this parameter.
On the Windows platform, this parameter must be specified as an encrypted value of the symmetric key.
To obtain an encrypted value, use the Get-ChatEncryptedUnicodeKeyCredential command.
On non-Windows systems or if the PlainTextApiKey option is specified, the parameter is specified via plaintext rather than as a securestring.
To avoid the value of the plaintext key being present in command history, use a command to read it from a secure location such as an Azure KeyVault or a local file with sufficient security measures in place, assign the value of the key to a PowerShell variable, and then use that variable to specify the value of the ApiKey parameter.

```yaml
Type: String
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ReadApiKey
Specify the ReadApiKey parameter to supply secure, interactive input for the API key instead of supplying it via the ApiKey or PlainTextApiKey parameters.

```yaml
Type: SwitchParameter
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PlainTextApiKey
Specify this if the ApiKey parameter being specified uses plaintext.
This parameter should only be used for troubleshooting such as confirming that the actual value of the API key is correct before using encryption.

```yaml
Type: SwitchParameter
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AllowInteractiveSignin
For use with remote models only, specify AllowInteractiveSignin to allow this command or subsequent commands that access the model to invoke a user interface for authentication.
This is only applicable when the ApiKey parameter or other non-interactive sign-in mechanisms are not configured for the session.
For some model services such as Azure OpenAI this option can be useful if sign-in tools such as the "Az.Accounts" module with its "Login-AzAccount" and "Logout-AzAccount" commands is unavailable, however it may have some side effects including multiple sign-in prompts.

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

### -LocalModelPath
For local models such as those supported by the LocalOnnx provider this is the path to the local model in the executing device's file system.

```yaml
Type: String
Parameter Sets: localmodel
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ModelIdentifier
This parameter may be required for certain providers, particularly for local models.

```yaml
Type: String
Parameter Sets: remoteaiservice
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: localmodel
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ServiceIdentifier
This parameter may be required for certain providers such as Ollama.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TokenLimit
Specifies the maximum number of tokens that should be sent to the model.
Tokens are units of semantic meaning similar to the concept of a "word"; messages sent to the model are interpreted as tokens, and models have a limit on the number of tokens that can be processed in a request or returned as a response.
The default value of 4096 may be sufficient for most use cases, but some models may support fewer tokens, so the value can be changed so that message commands can attempt to "compress" messages at the expense of losing context / meaning.
Alternatively, models that have much higher limits can be fully utilized by setting this value higher so that commands will not prematurely attempt to throw away valuable context.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 16384
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TokenStrategy
Specifies the mechanism to use to "compress" messages into fewer tokens (see the TokenLimit parameter for more information on tokens and their impact on conversations and accuracy).
By default, the Summarize strategy is used, which will attempt to shorten conversation history by summarizing it and using this smaller summary result to continue conversations once the token limit is reached.
The Truncate strategy simply removes a selected set of older messages from the conversation histroy under the assumption that the conversation can be reasonably continued by considering the most recent messages.
The None strategy means no attempt will be made to reduce token utilization; this will likely limit the number of exchanges in a conversation, but can allow the user to handle errors that occur when token limits are hit with custom scripting, or can simply be useful in testing or ruling out non-determinism that could be caused by removing conversation context.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Summarize
Accept pipeline input: False
Accept wildcard characters: False
```

### -HistoryContextLimit
Specify this parameter to limit amount of conversation history submitted to the model.
The default value of -1 means that there is no limit to the history, though the conversation history is still subject to the token manangement strategy specified by the TokenStratey parameter.
Specify a value greater than -1 for this parameter to define the number of most recent pairs of past user / assistant response messages that should be included when processing new messages from the user.
A value of 0 for instances means no previous conversation history should be included; each message sent to the model from the user will be interpreted as if it is the first time the user has sent a message; this will be like interacting with an entity that has no memory.
A value of 1 will mean that the previous user message and the resulting response from the assistant will be included has history, a value of two means the the history will include the two previous user / assistant messages as history, and so on.
This parameter is commonly only needed for very customized use cases; generally the most natural conversation / interaction flow will result when the default value of -1 is used to include as much history as context as possible.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### -SendBlock
The SendBlock parameter allows specification of a PowerShell script block that is executed before user input is sent to the model.
The first parameter of the scriptblock is the user input, and the output of the script block is the actual text that will be sent to the model.
This can be used pre-process text sent to the model, which can be particularly useful in validating user input or performing reliable deterministic transformations on the input.
If an exception is thrown by the script block the command used to send the message will fail and the message will not be sent.
The chat history of the session will reflect the text that was returned by the scriptblock and thus sent to the model, not the text that was directly provided by the user to the scriptblock.

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

### -ReceiveBlock
The ReceiveBlock parameter allows specification of a PowerShell script block that is executed after the model has returned a response message and before the response is relayed as the output of a command.
The first parameter of the scriptblock is the model's response, and the output of the script block is the text that should be returned to the command that triggered the response.
This can be used post-process text received from the model, which is useful for providing additional formatting or other processing in a deterministic fashion as opposed to allowing the model to perform the processing.
If an exception is thrown by the script block the command used to send the message will fail and the response will be treated as an error.
The chat history of the session will reflect the text that returned by the scriptblock after processing the model's response, not the text that was returned directly by the model.

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

### -Plugins
{{ Fill Plugins Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginParameters
{{ Fill PluginParameters Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowAgentAccess
This parameter enables "agent" behavior, i.e.
the ability of ChatGPS to leverage plugins configured through the Add-Plugin command to automatically send information about the local computer to the model service AND also to take local actions (e.g.
issuing web search requests, creating files locally) based on responses from the model; these behaviors occur on your behalf.
This setting is required for commands such as Add-Plugin to have any impact; without this setting any plugins configured through Add-Plugin are ignored.
This setting is also equivalent to enabling "function calling" features of the model.

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

### -PassThru
By default, Connect-ChatSession returns no output; it simply has the side effect of changing the current session.
Specify PassThru to return the value of the session regardless whether the current session is overridden (default behavior) or not (when NoSave is specified).
The resulting output may be used as a parameter to other commands that access models such as Send-ChatMessage, Start-ChatShell, or Invoke-ChatFunction.

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

### -NoSetCurrent
Specify NoSetCurrent so that the implicit "current" session is not overwritten or otherwise set when this command executes successfully.
Instead, a new session independent from any current session will be returned as output of the command.
The resulting output may be used as a parameter to other commands that access models such as Send-ChatMessage, Start-ChatShell, or Invoke-ChatFunction.
Thus Connect-ChatSession can be used to create multiple independent chat sessions for different purposes without affecting the current default session.

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

### -NoSave
By default, all sessions returned by the Connect-ChatSession command are saved in a list of connections that can be viewed by the Get-ChatSession command and otherwise managed by the Select-ChatSession and Remove-ChatSession commands.
Specify the NoSave parameter so that Connect-ChatSession does not add the session created by this invocation to the session list.
This is useful for maintaining "private" sessions visible only to certain scripts or commands; the limited visibility protects those sessions from being corrupted or deleted by other applications or scripts.
When this parameter is specified, the command will output the newly created connection even if the PassThru option is not specified.

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

### -NoConnect
By default, this command may attempt to authenticate to the service that hosts the model (for remote models) or access the model's local path (for local models) in order to surface incorrect parameters or access problems before the session is actually used with subsequent commands.
To skip this verification, specify the NoConnect parameter.
Specifying this may mean that access issues are not discovered until subsequent commands that access the model are executed.

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

### -Force
Use the Force parameter to create the session even if the name specified by the Name parameter is already in use by an existing session in the session list.
When this situation occurs, the existing session is removed from the list before the new session is created, effectively replacing or overwriting it.
Additionally, if the session that would be replaced is the current session, the command will still succeed; however if the NoSetCurrent parameter is also specified then there will no longer be a current session.

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

### -NoProxy
Specify the NoProxy parameter so ensure that the session will not use an intermediate proxy process to communicate with the model.
By default, the session will utilize a proxy that isolates dependencies for the services used to access the language model into a separate process from that of the PowerShell session.
This helps avoid incompatibilities with such dependencies and PowerShell itself, and was useful during the early stages of the development of Semantic Kernel which changed frequently.
In some cases such as specification of the AllowInteractiveSignin parameter the proxy will not be used due to known user experience issues in that situation.
The ForceProxy parameter may be used to force use of the proxy in call cases.
At some point the proxy may no longer be required and may eventually be removed.
It is possible that code defects in the proxy could introduce errors or other reliability issues, so NoProxy can be specified to remove this risk if problems arise in certain use cases.
When the proxy is in use, a log of its activity can be generated if the appropriate values are specified for the LogLevel and LogDirectory parameters.

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

### -ForceProxy
Use ForceProxy to override the command's automatic determination of when to use a proxy process to host language model service dependencies and use the proxy in all cases.
This parameter is most likely useful for debugging purposes only and should not be needed.

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

### -LogDirectory
This parameter allows a log to be placed in a certain directory; the log contains information about a local proxy used to isolate the code that interacts with services.
If this parameter is not specified, then no long will be written, even if the LogLevel is set to something other than None.
If this parameter is specifed, then a file with the name ChatGPSProxy.log will be placed in that directory.

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

### -LogLevel
This parameter only takes effect if LogDirectory is also specified as a valid location for writing a log of proxy operations sent to a local process that interacts with the services that provide the model.
By default, the value "Default" currently means there is no logging, which is the same as the value None.
A value of Error shows only logs related to errors.
The value Debug shows Errors and other common events, and the DebugVerbose shows the highest level of information in the log.

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

### By default, the command has no output. But if the NoSave or PassThru parameters are specified, the newly connected session is returned as output and can be used as a parameter to other commands.
## NOTES

## RELATED LINKS

[Get-ChatSession
Select-ChatSession
Remove-ChatSession
Send-ChatMessage
Get-ChatConversation
Get-ChatLog
Clear-ChatConversation
Start-ChatShell
Invoke-ChatFunction
Add-Plugin]()

