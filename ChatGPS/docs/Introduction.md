|[Commands](CommandReference.md)|
|--------------------|

# Welcome -- What is ChatGPS?

ChatGPS is a tool for interacting with large language models (LLMs) using PowerShell. You can use it to:

* Generate useful PowerShell scripts from words, not code
* Incorporate AI into PowerShell-based automation
* Build agents: enable language models to invoke operations on your system or APIs
* Use the capablities of PowerShell with little to no PowerShell expertise
* Get AI-assisted help about PowerShell or other command-line tools without leaving your terminal

Concretely, ChatGPS provides commands that let you send natural language prompts to a model, and receive human-like responses, for example:

```powershell
Send-ChatMessage "In which year was Toni Morrison awarded the Nobel Prize in Literature?"

Received                 Response
--------                 --------
8/20/2025 5:43:24 AM     Toni Morrison was awarded the Nobel Prize in Literature in 1993.
```

Conversation is just the start. You can use natural language to direct the model to generate working PowerShell code. ChatGPS can even take the next step and execute the code. And you can configure ChatGPS so that your conversations include information about your local system or other services you have access to; this allows you to use the language model to perform local operations such as analyzing local source files, summarizing documents, or schematizing partially structured or unstructed data files.

# How do I install it?

ChatGPS is published to [PowerShell Gallery](https://powershellgallery.com), so you can easily install it from PowerShell itself:

```powershell
Install-Module ChatGPS
```

# What are the prerequisites for using ChatGPS?

You'll need access to a language model, which is not included with ChatGPS itself. ChatGPS supports both remotely hosted models like those provided by Microsoft's Azure OpenAI product, OpenAI, Anthropic, Google, etc., and also locally hosted models like Onnx and Ollama.

If you're already using language models from providers like these, you can skip ahead to the section on making your first request to a model.

## Getting access to a model

If you're new to language model products or have only interacted with AI models indirectly through AI user interfaces embedded in other products, you'll need to provision a model through an account with a provider of model APIs or host a model on your local computer:

* Remote: Provide your model's authentication configuration (often an API key or OAuth2 parameters) and any http API endpoint information, the identifier for the specific model you want to use, as well as any other configuration required by the model's provider.
  * Register for an account with the model provider, use the account to choose / enable a particular model, and then access the configuration required for that model and your account.
* Local: Local models generally do not need authentication information, but you will still need to identify the model by specifying a local file system path or local HTTP URI along with provider-specific configuration parameters.
  * Refer to the provider's configuration and installation (more below) procedure. For some providers you'll need to expicitly download the model to the local file system using HTTP or even `git`. Other providers distribute software which will do this for you.

Typically remotely hosted models are more powerful in terms of both speed and "reasoning" capability because they can utilize cloud-based compute and memory resources far more powerful than your own computer system, and in general they don't require provider-specific software to be installed on your computer, they simply require configuration.

For local models, you'll need to install provider-specific inferencing software in addition to ChatGPS because there is no single standard for inferencing that is compatible with all model providers. Providers such as Ollama distribute an installation package. For Onnx models, ChatGPS provides an installation command to install the Onnx inferencing libraries. In general, "smaller" language models (i.e. those with fewer parameters) with a size under 1 GB will run better on your hardware than the larger models (hundreds of gigabytes for the largest models like GPT 5). The performance of local models will depend strongly on your system's resources, especially total physical RAM, the video meory of your graphics processing unit(s) (GPUs), your CPU, and overall memory and system-bus speed.

## I'm ready, show me some commands!

If you've installed ChatGPS and you have access to a model as described above, you can use the `Connect-ChatSession` command to create a session, and then issue any number of invocations of `Send-ChatMessage` to send a message to the model and receive a response. By default, `Connect-ChatSession` assumes you're using an OpenAI model, so if you have an API key for OpenAI, you can use it as follows:

```powershell
PS > Connect-ChatSession -ModelIdentifier gpt-4o-mini -ReadApiKey
ChatGPS: Enter secret key / password>: ***************

PS > Send-ChatMessage 'Hello World!'

Received                 Response
--------                 --------
8/20/2025 9:25:20 PM     Hello! How can I assist you today?
```

You can continue to invoke `Send-ChatSession` and it will send a new message using the same session, and also add that message and responses from the model to the overall conversation. You can review previously ent and received messages using the `Get-ChatLog` command.

### Models other than OpenAI

You can use models from other providers as well, though some models may require a different set of parameters to be specified to `Connect-ChatSession`. If you're using Azure OpenAI, you'll need to supply the API endpoint of your Azure OpenAI resource and specify a deployment name instead of a model identifier, so you can replace the use of `Connect-ChatSession` above with this version and follow it up with `Send-ChatMessage`:

```powershell
Connect-ChatSession -DeploymentName gpt-4o-mini -ApiEndpoint https://your-openai-resource.openai.azure.com -ReadApiKey
```

The Azure OpenAI provider also supports authentication through an OAuth2 client identifier used by Azure's `Az` PowerShell module and also the `az cli` tool, and this allows you to avoid the less secure use of an API key if you're able to sign in to those tools using Entra ID accounts that you've configured for access on your Azure OpenAI resource:

The `Connect-ChatSession` command attempts to "guess" whether you're using OpenAI, Azure OpenAI, etc., but for other models you need to be explicit and specify the `Provider` parameter, which is always allowed. This example lets you use a local `Ollama` model, which requires that you have installed the `Ollama` client software and used it to download and configure a model:

```powershell
Connect-ChatSession -Provider Ollama -ModelIdentifier llama3:latest
```

Anthropic's model service is also available using a command like the following:

```powershell
Connect-ChatSession -Provider Anthropic -ModelIdentifier claude-sonnet-4-20250514 -ReadApiKey
```

### Multiple sessions

Note that you can have multiple sessions and switch between them. Each session has a separate conversation history, so this multi-session capability is useful whenever you need to maintain multiple conversations. And each session can use a different model, so the need to use different language models is another relevant multi-session situation.

It's easy to create multiple sessions -- each invocation of `Connect-ChatSession` creates a new session -- it does not delete previous sessions when it creates a new one. To see all sessions that have been created, use the `Get-ChatSession` command:

```powershell
PS > Get-ChatSession

Info   Name                                   Model                    Provider    Count
----   ----                                   -----                    --------    -----
+rd-   AnthropicTest                          claude-sonnet-4-20250514 Anthropic   1
+rd-   codegen                                gpt-4.1-mini             AzureOpenAI 1
 rd- > Azure-4o                               gpt-4o-mini              AzureOpenAI 1
 rd-   gemini-2.0a                            gemini-2.0-flash-001     Google      1
 l--   llama3                                 llama3:latest            Ollama      1
 rd-   storyteller                            gpt-4o-mini              OpenAI      1
 l--   phi35local                             phi-3.5                  LocalOnnx   1
 rc-   (91a3b80e-f914-4362-a44e-11b144798e10) gpt-4o-mini              AzureOpenAI 1
```

This shows that optionally providing a concise, friendly name for a session is a great way to make it easy to understand the purpose of one session vs. another. You assign names to sessions at creation time by specifying and optional `Name` parameter to `Connect-ChatSession`:

```powershell
PS > Connect-ChatSession -Name CodeAnalysis -Provider Anthropic -ModelIdentifier claude-sonnet-4-20250514 -ReadApiKey
```

### The current session

In the output above from `Get-ChatSession`, the session with the ">" character is the current session, the one which is used by commands like `Send-ChatMessage`. Any command that uses a session has a `Session` or `SessionName` parameter that can be used to direct the command to use a different session based on the session's `Name` or `Id` property. You can also switch between sessions using the `Select-ChatSession` command and specifying a session name or id, which may also be accessed through the alias `scs`:

```powershell
PS > Select-ChatSession codegen
```

Note that by default `Connect-ChatSession` sets the current session to the newly created session. You can avoid this behavior by specifying the `NoSetCurrent` parameter to `Connect-ChatSession` when you create a new session and the current session will not change when you invoke the command.

### Save your connections

ChatGPS maintains a settings file at `~/.chatgps/settings.json` where you can save session configurations so that you don't have to enter all of the `Connect-ChatSession` parameters every time you start PowerShell. Whenever the module is imported, the file is read by ChatGPS and then session configuration among other settings stored in the file is read and sessions are recreated based on the information in the file.

To save a session to the file, Use the `Save-ChatSessionSetting` command:

```powershell
PS > Save-ChatSessionSetting -Current
```

By specifying the `Current` parameter, this saves the current session. If the session you want to save has a friendly name (it was created by using the `Name` parameter with `Connect-ChatSession`), you can just specify the name to save it whether it is the current session or not:

```powershell
PS > Save-ChatSessionSetting storyteller
```

Note that if you save a setting that has no name, by fault it will get a generated name that might not be as useful as one chosen intentionally. You can add the `SaveAs` parameter when saving any session with `Save-ChatSessionSetting` to write the session to the file with that friendly name; it also has the side effect of creating a new session with that name as if you had invoked `Connect-ChatSession` command to create it.

You can then start new PowerShell sessions, reboot your system, etc., and whenever the `ChatGPS` module is imported, the connections saved in the settings file will be recreated; you can verify this by invoking the `Get-ChatSession` command to enumerate sessions.

It is also possible to simply edit the settings file with a text editor as the properties specified for connections in the file possess names aligned to the corresponding parameters of `Connect-ChatSession`; if you make mistakes in editing the file, `ChatGPS` will skip errant settings and issue a warning, so be sure to back up the file before making changes so you can recover from such errors.

## Interactive chat with Start-ChatShell

The ability of the `Send-ChatMessage` command to send a message to the language model and receive a response is useful for one-off queries or automation use cases where language model interactions are incorporated into PowerShell scripts. However, the requirement to issue a valid PowerShell command for each turn of an ongoing conversation is an unnatural and awkward impediment for the human side of any human-model interaction. To facilitate a more natural "chat" interaction like that used by humans communicating through computing devices, use the `Start-ChatShell` command:

```powershell
PS > Start-ChatShell

(Azure-4o) ChatGPS>: Hello

Received                 Response
--------                 --------
8/21/2025 9:07:10 PM     Hello! How can I assist you today?

(Azure-4o) ChatGPS>: What is the command to create symbolic links in Windows?

8/21/2025 9:10:10 PM     In Windows, you can create symbolic links using the `mklink`
                         command in the Command Prompt.


(Azure-4o) ChatGPS>: Is there a Powershell command that can do this?

8/21/2025 9:11:31 PM     Yes, you can create symbolic links in PowerShell as well using
                         the `New-Item` cmdlet with the `ItemType` parameter. Here’s the syntax:

                         New-Item -ItemType SymbolicLink -Path <Link> -Target <Target>
```

The `Start-ChatShell` command, which is also accessible through the alias `chatgps`, starts an interactive Read-Eval-Print-Loop (REPL) that allows you to enter free-form text instead of PowerShell commands; in response you'll receive text from the model formatted to delineate the turns of the conversation similar to text message interfaces or user experiences found in Internet Relay Chat (IRC) clients used by humans to communicate with other humans.

Since any text you enter is sent to the model and returned, you'll need to enter a special input sequence to return to PowerShell's command intepreter. Just enter the subcommand `.exit` to exit `Start-ChatShell`. There are additional "`.`" subcommands available within the `Start-ChatShell` REPL; use the subcommand `.help` to list them all.

## System prompts and customization

Sessions created by the `Connect-ChatSession` are initialized with a *system prompt,* natural language instructions that serve as inviolable rules to be reliably adhered to by the language model to constrain its responses, regardless of attempts by the user to elicit responses that transgress those rules. Any other instructions you provide to the model during a conversation have lower precedence than the system prompt, which is always present and treated as superseding everything else in the conversation; it is essentially set in stone for the session.

`Connect-ChatSession` creates session with an open-ended system prompt that allows for conversations on any topic not otherwise prohibited by the specific model itself (models are trained to avoid harmful content in their responses even in the absence of a strict system prompt).

You can override `Connect-ChatSession`'s default system prompt to serve a specific purpose, such as ensuring that responses adhere to a particular topic or conversation style using the command's `SystemPromptId` and `CustomSystemPrompt` parameters.

### Built-in system prompts

Specify the `SystemPromptId` parameter for `Connect-ChatSession` to choose from a number of options, including:

* General: This is actually the default, allows any topic and does not specify a particular conversation style
* PowerShell: Responses are limited to PowerShell-specific topics
* PowerShellStrict: Responses are limited to actual PowerShell code
* Conversational: Like General, but attempts to be engaging and fun
* Terse: Answers questions with very concise and short responses, suppresses the tendency of some models to elaborate and go beyond the original question.

### Custom system prompts

Rather than choose from a limited, fixed set, use `CustomSystemPrompt` to provide the *exact* instructions to govern the conversation. You may need to test multiple versions of your prompt with various messages from `Send-ChatMessage` or `Start-ChatShell` to ensure the system prompt has the desired effect in terms of tone or otherwise maintaining the model's conversation topics. Here are a few examples

*Python:* 
```powershell
Connect-ChatSession -ModelIdentifier gpt-4o-mini -ReadApiKey -CustomSystemPrompt "
   You are a Python producer: you respond to the user's messages with Python code that
   produces a result that corresponds to the user's question or the meaning or outcomes
   of the user's word's. You *only* respond with well-formed Python code. If you cannot
   map the user's words to Python code, you may output a Python comment that indicates
   that you cannot answer the question and why."
```

*Application finder:*
```powershell
Connect-ChatSession -ModelIdentifier gpt-4o-mini -ReadApiKey -CustomSystemPrompt "
   You are an assistant who lists applications that provide the functionality indicated
   by the user's input, or are related to the topic of the user's input. You only
   respond with lists of relevant applications, and you return no more than 5 such applications.
   For each application your response must include the last known publisher of the application.
   If you can identify a link to purchase or download the software, that should be included as well.
   The response must be formatted as Markdown, with all information for a given application on a single line.
   If you cannot identify a single such application, you can just say that in your response. You do
   not respond with any output other than that described above."
```

*Translator:*
```powershell
Connect-ChatSession -ModelIdentifier gpt-4o-mini -ReadApiKey -CustomSystemPrompt "
   You are an assistant who translates the user's text from English to Spanish. You
   will respond only in Spanish, unless the user directly asks you to explain a previous
   response you gave -- in that case, you can answer in English, but the topic can only be
   related to a previous Spanish response."
```

# Chat functions: turn AI into PowerShell commands

So far, we've explored how ChatGPS allows you to conduct conversations with language models to get answers to questions posed as natural language or to process unstructured input. But within the environment of a PowerShell session or software development in general, conversations are often less efficient than simply invoking a repeatable, deterministic command or programming language code. ChatGPS allows you to combine the deterministic benefits of standard software idioms like functions or commands with the flexibility and power of AI to process natural language or unstructured input using *chat functions":

```powershell
PS > New-ChatFunction -name Translator 'Translate the text {{$sourcetext}} into the language {{$language}} and respond with output only in that language.'

Id                                   Name       Definition             Parameters
--                                   ----       ----------
59880abc-166f-48fd-a96d-220f793c4f57 Translator Translate the text {{$ {[language, language], [sourcetext, sourcetext]}

PS > Invoke-ChatFunction Translator -Parameters 'I use PowerShell for both work and play.', Spanish
```

The command `New-ChatFunction` creates a function named `Translator` that is defined by natural language. The parameters of the function, in this case `sourceText` and `language` are declared inline with the function using the standard [Handlebars](https://handlebarsjs.com/) syntax with double braces and a `$` character (because of the use of the `$` character is it is convenient to use PowerShell's single quote character to enclose chat function definitions to avoid confusion with PowerShell's use of `$` when double quotes are used).

The function is then used to translate some text from English to Spanish through the `Invoke-ChatFunction` command which takes the function name `Translator` assigned with `New-ChatFunction` and its parameters (passed in order of appearance in the string in this case, though they can also be passed by name).

And if desired, you can dispense with the use of `Invoke-ChatFunction` altogether and simply bind the chat function to a native PowerShell function for a more natural PowerShell syntax or simply for convenient usage within scripts. To create such "normal" PowerShell functions, use `New-ChatScriptBlock` with the `BindToNativeFunctionName` parameter assigned with the name of the PowerShell function you wish to assign to the chat function:

```powershell
PS > New-ChatScriptBlock 'Translate the text {{$sourcetext}} into the language {{$language}} and respond with output only in that language.' -BindToNativeFunctionName Translate-Text
PS > Translate-Text -sourcetext 'I can translate text using PowerShell!' -language Spanish
¡Puedo traducir texto usando PowerShell!
```

Here `New-ChatScriptBlock` creates a "normal" PowerShell Script Block bound to a command called `Translate-Text` which uses the language model to produce its output. A user of `Translate-Text` who was not aware of how it had been defined using ChatGPS commands would not realize that a language model was involved in generating its output.

Note that chat functions can also utilize a session's *plugins* (see below) that can access resources on the local system or even remote systems, further expanding the power of chat functions. A key limitation of chat functions however is that they cannot function without a language model in a ChatGPS session, and in fact, they cannot function without ChatGPS itself, so when you use them, you must be sure that the ChatGPS module is imported into PowerShell before invocation.

# Generating PowerShell scripts and other code

It might be tempting to think of chat functions as a way to extend PowerShell such that you never really need to write PowerShell code again -- you can simply define chat functions with natural language, and use those chat functions within PowerShell. Even with models continuing to improve however, this is fairly impractical simply because language models are only efficient for specific kinds of problems that are difficult to solve with traditional software. For any problem that can be solved with typical programming / scripting languages like C#, Rust, C++, Java, Python, Javascript, or Powershell, language models are best are a very computationally expensive and slow way to solve a problem. And in the general case language models are not reliable and will return incorrect answers for even for cases that humans can solve with ease (often after bearing a certain amount of tedium) such as adding or multiplying two large (e.g. more than 5 digit) numbers.

However, language models are still useful in these domains as they do a much better job of **generating code for an algorithm** to solve a problem rather than actually **executing an algorithm** to solve it. So instead of using a chat function for a problem that does not require the capabilities of a language model (e.g. language translation is something that justifies a language model vs. traditional software), you can still use the model to generate the code. You use the model once and repeatedly use its output code, which is far more efficient than repeatedly using the model to compute results equivalent to the code; the less you use the model, typically the more efficent you'll be. And of course, any such generated code can run without access to a language model at runtime, so it can run in any environment that supports the code's target language runtime, even if language models cease to exist altogether. :)

ChatGPS provides the `Generate-ChatCode` command (actually an alias for `Build-ChatCode`) to support this scenario:

```powershell
PS > Generate-ChatCode 'For a given file path return its file version information' -FunctionName Get-FileVersion

[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

# Check if the file exists
if (-Not (Test-Path -Path $FilePath -PathType Leaf)) {
    Throw "File not found: $FilePath"
}

# Get the file version info
$fileVersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath)

# Return the file version information object
$fileVersionInfo

PS > Get-FileVersion (Get-Command pwsh | Select-Object -ExpandProperty Source)
```

The `Generate-ChatCode` command outputs PowerShell code in this case (use the `Language` parameter to generate code for languages other than PowerShell) and by specifying the `FunctionName` parameter this code is bound to a PowerShell function called `Get-FileVersion`. This function is just a normal function and can be used without access to a language model or an active ChatGPS session.

To generate code that lasts beyond the current PowerShell session, you can simply send the generated code to a file, such as in this example below:

```powershell
"Generate list of all prime numbers less than a given number N" | Generate-ChatCode | Out-File ./Get-Primes.ps1
PS > & ./Get-Primes 10
2
3
5
7
```

The generated code was piped to a `.ps1` PowerShell script file, which is then executed like any normal PowerShell script; even after the PowerShell session terminates, the script will still be present in the file system and can be invoked by any future PowerShell session, even if ChatGPS is uninstalled from the system and no language models are accessible from the system. This particular script has no dependencies so it could be sent to other computer systems and executed successfully on those systems.

# So what about agents (and plugins)?

Yes -- ChatGPS lets you make agents!

## Wait, what is an agent?

As of now, the term agent lacks a precise definition and even as a concept is poorly defined. For out purposes, we'll use the following definition for an "AI agent:" *An AI agent is software that accesses local or remote resources based on instructions from an AI system guided to act on behalf of a user." While it's possible that the ablity of `Send-ChatMessage` to send messages from a user to a an AI language model might correspond to the latter half of our definition, is there a role that other `ChatGPS` commands can play in the first half, i.e. the ability to follow the model's resulting instructions to access resources?

Indeed, ChatGPS enables the use of plugins, which are software components that can be advertised to language models through `Send-ChatMessage`, which may result in a response from the language model instructing `ChatGPS` to execute the plugin's code if the model determines that the user's intent as expressed by the prompt given to `Send-ChatMessage` would be satisfied by doing so.

But what are these ChatGPS plugin commands?

### Adding plugins to the session

Let's imagine the year is 2025 -- let's use ChatGPS to ask a GPT-4o-mini model to respond with the current date:

```powershell
PS > Send-ChatMessage "what's the current date?"

8/14/2025 1:12:44 PM   Today's date is October 3, 2023.
```

Clearly this is wrong, but not unexpected, since the model is just generating a response from its training data, which is not updated beyond the date at which its training was completed. We can fix this by adding one of the plugins included with `ChatGPS`, the `TimePlugin` plugin:

```powershell
PS > Add-ChatPlugin TimePlugin
PS > Set-ChatAgentAccess -Allowed
PS > Send-ChatMessage "and now what time is it? :)"

Received                Response
--------                --------
8/14/2025 1:15:15 PM    The current time is 1:15 PM on Thursday, August 14, 2025
```

First, the plugin is added to the current session using the `Add-ChatPlugin` command. But for `ChatGPS` to be able to access that plugin, the session must also be enabled for "agent access," so the `Set-ChatAgentAccess` command is used with the `Allowed` parameter to allow plugin access. After performing these steps, when a message is sent to the model in that session, the message will also include the fact that `TimePlugin` is available to answer questions about time, and the model's response will include directions for `ChatGPS` to follow to run the time plugin, which contains simple code to return the current time. After it is executed, `ChatGPS` will send back the time to the model, allowing the model to construct the final natural language response that correctly answers the question about the current time.

Note that `Connect-ChatSession` includes parameters to add plugins at session creation time, as well as to allow agent access, to avoid the need to subsequently run `Add-ChatPlugin` and `Set-ChatAgentAccess`.

Since sessions can have multiple plugins added, let's add the `Google` plugin which enables web searches -- the `Get-ChatEncryptedUnicodeKeyCredential` command allows you to enter that plugin's API key securely. With both the time plugin and the Google plugin, we can get answers to questions that require the model to know the current time and have access to search engine results:

```powershell
PS > $apiKey = Get-ChatEncryptedUnicodeKeyCredential
ChatGPS: Enter secret key / password>: ***************************************

PS > $googleSearchEngineId = 'fijsAx09934'

PS > Add-ChatPlugin Google apikey, searchEngineId $apikey, $googleSearchEngineId

PS > Send-ChatMessage "Who won last night's women's professional basketball game between Seattle and Dallas?"

Received                 Response
--------                 --------
8/23/2025 6:21:57 AM     Seattle played a game against Dallas yesterday, August 22, 2025. They won
                         won decisively with a final score of 94-58.
```

This simple "agent" has performed a web search on your behalf. Additional plugins can expand the capability of such agents with the ability to read the local file system, write(!) files, make HTTP requests that read or even update data, etc., all based on natural language instructions rather than code. Some simple PowerShell scripting on top plugin-enabled ChatGPS sessions could build agents that follow your natural language instructions to purchase supplies, pay invoices (!), manage your email, maintain your code / fix its bugs, order food... :).

To learn about the additional plugins available to ChatGPS, invoke `Get-ChatPlugin -ListAvailable` to see a list of plugins and their descriptions.

### Make your own plugins

You can even build your own plugins by providing a description of your plugin's capabilities along with PowerShell code that implements the actual functionality. This is accomplished through the `Add-ChatPluginFunction` and `New-ChatPlugin` commands:

```powershell
Add-ChatPluginFunction system_uptime { Get-Uptime } -Description 'Retrieve the uptime of the operating system' |
  Add-ChatPluginFunction get_system_updates  {
      param ([int]$Days = 30) Get-HotFix | Where-Object { $_.InstalledOn -gt (Get-Date).AddDays(-$Days) }
  } -Description 'Returns the list of operating system updates applied to the system in the last N days' |
  Add-ChatPluginFunction get_os_drive_free_space { (Get-PSDrive ($env:SystemDrive).Trim(':')).Free
    } -Description "Returns the amount of free disk space in bytes for the drive that hosts the operating system.' |
  Register-ChatPlugin system_basic_information -Description 'Returns basic information about the operating system'

Name                           Desciption                                           Parameters
----                           ----------                                           ----------
system_basic_information       Returns basic information about the operating system
```

This plugin consists of three "plugin functions" created by the `Add-ChatPluginFunction` command -- these commands build a collection of such functions using the pipeline in the example above, which is finally piped to `Register-ChatPlugin` to register a new plugin which will then be enumerable along with the other "built-in" plugins by invoking `Get-ChatPlugin -ListAvailable`. More importantly, that means it can be added to a session through `Add-ChatPlugin`:

```powershell
PS > Add-ChatPlugin system_basic_information
PS > Send-ChatMessage "What were the last three operating system updates applied to this system, and when were they applied? Please include identifiers of the updates and any basic description when listing them."

Received                 Response
--------                 --------
8/23/2025 8:09:20 AM     Here are the last three operating system updates applied to this system:

                         1. **Update Identifier:** KB5056579
                            **Description:** Update
                            **Installed On:** May 17, 2025

                         2. **Update Identifier:** KB5063878
                            **Description:** Security Update
                            **Installed On:** August 13, 2025

                         3. **Update Identifier:** KB5065381
                            **Description:** Security Update
                            **Installed On:** August 13, 2025

                         These entries provide a record of recent updates, including their identifiers, descriptions,
                         and installation dates.
```

### From awareness to doing: agents that act for you

So agents can interact with real world resources, e.g. the computer, web services, etc. to find information for me and even provide recommendations based on the data they uncover. But can they *do* anything, i.e. can they go beyond recommanding a course of action to actually taking that action? Well, in many cases yes!

Plugins, including custom plugins you define through `Register-ChatPlugin` are just code that runs on your system, and like any code they can perform both read-only and write actions. However, write actions require a very high level of trust even when delegated to another human being. Current AI systems are not nearly as reliable as humans in making sensible decisions (see the known tendency of large language models to "hallucinate" and reach incorrect or nonsensical conclusions), and crucially as mere prediction systems they lack the basic level of judgement that can be expected of humans even when they operate in unfamiliar problem domains. And in the end these systems aren't people -- they lack accountability, so if they take any damaging actions, who is to blame, and who will fix resulting adverse outcomes? :)

So for this introductory section, write actions are out of scope as an advanced concept. ChatGPS *does indeed* readily provide you the ability to build agents that can actually act on your behalf. Design such plugins and agents with care, and as tools like ChatGPS and language models develop guardrails to manage the risk of such capabilities, adopt any such safety protocols as soon as you can. And regardless, deploy agents with write capability with caution and some mechanism to ensure that appropriate recovery and accountability abilities are available in the event of errors / malfunctions in the agent.

# Miscellaneous features

If you explore the [command reference](commands), you can dive into the details of each command to learn about additional features. Here are just a few of them:

* `Send-ChatMessage` provides an `AsJob` parameter to execute the command asynchronously as a PowerShell job returned by `Start-Job`. This is useful when language models take a long time to respond (local models in particular running on your local computer will tend to be slower than remote models inferencing on high-powered cloud infrastructure) and you want to complete other tasks in your PowerShell session.
* `Send-ChatMessage` has a `ReceiveBlock` parameter that allows you to specify a PowerShell script block to add additional processing to any text responses from the model. This could be used to add color or highlighting to certain words in the model's response for instance.
* `Send-ChatMessage` also has a `ReplyBlock` parameter that allows you to specify a script block that will automatically reply (or optionally not reply) to responses from the model.
* `Start-ChatShell` has similar `ReceiveBlock` and `ReplyBlock` parameters
* `Start-ChatShell`'s (and `Send-ChatMessage`'s) `OutputFormat` parameter allows you to alter the output of the REPL -- it supports rendering markdown for instance, or just emitting raw text rather than column-formatted requests and responses with time stamps.
* Use `Get-ChatLog` to review all past messages in a session, and `Get-ChatConveration` to see the possibly "compressed" list of conversation messages used by the language model to generate responses.
* Use `Clear-ChatConversation` to start a brand new converstion in the session; `Get-ChatLog` will still show previous messages, and you can clear those with `Clear-ChatLog`

# What's next?

ChatGPS exposes the natural language processing capabilities of large language models to you as standard PowerShell commands, and allows you to integrate them into your everyday PowerShell workflow and scripts.

* Are there scripts you've put off writing because you weren't sure where to start? You can use `Start-ChatShell` to chat with your favorite language model about it, or try out `Generate-ChatCode` to see if the language model can build part (or all!) of your script.
* Do you need to extract structured information out of unstructured data or files? Now is your chance to build a chat function with `New-ChatFunction` or `New-ChatScriptBlock` to apply AI to wrangling that irregular data.
* Are you looking to build (possibly autonomous) agents that can perform tasks on your behalf? `Add-ChatPlugin` and even `Register-ChatPlugin` will let you (carefully!) expose parts of your system and even software services to instructions from a language model based on the goals you give it.

You don't have to start with grandiose goals, so whatever tasks or abilities you've wanted to automate or even delegate away, consider even the smallest of those as a test case for language models, and over time you may find yourself able to focus on those most rewarding pursuits of your vocation rather than the merely obligatory.


