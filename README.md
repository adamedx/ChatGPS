ChatGPS
=======

**ChatGPS** enhances your interactive and scripted PowerShell sessions with artificial intelligence. With ChatGPS you can:

* Generate PowerShell code from natural language prompts within your PowerShell interactive experience
* Create AI PowerShell functions / commands based on natural language instead of PowerShell code
* Integrate AI into your PowerShell script library
* Get help / "how-to" advice about PowerShell in the context of your existing PowerShell session
* Create AI chatbots, whether purely conversational or focused on a specialization of your choosing
* Automate testing of various AI models

ChatGPS allows you to choose the AI model that powers its experience and supports both remotely hosted models such as those provided by Azure OpenAI, Open AI, etc., as well as locally hosted models like Phi 3.

ChatGPS is built on [Semantic Kernel (SK)](https://github.com/microsoft/semantic-kernel), and therefore should work well with any models and AI capabilities supported by SK.

# System requirements

* [PowerShell](https://github.com/PowerShell/PowerShell) 7.4 and higher on Windows, Linux, or MacOS
* Models -- bring your own!
  * Remote: valid account credentials to a service like Azure OpenAI, OpenAI, etc.
  * Local: for locally hosted models, GPU or NPU capabilities may be needed, see specific model requirements

# Development and testing

## Prerequisites

* Clone the repository, e.g. from PowerShell `git clone https://github.com/adamedx/ChatGPS`
* Install the [.NET 8 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)
* Install the `Pester` PowerShell test framework (skip this if you don't need to run tests): `install-module pester`

## Build

* Start a PowerShell 7 session -- the environment must be configured with the .NET tools described earlier
* Set the current working directory to the root of this cloned repository, e.g. `cd ~/src/ChatGPS`
* Execute the standard .net SDK build command:
```powershell
dotnet build
```
This will produce an importable PowerShell module with a relative path to the repository root like `./ChatGPS/bin/Debug/net8.0/Module`.

## Testing

### Unit testing

To run the unit tests, invoke the following PowerShell command from the root of the repository:

```powershell
import-module ./ChatGPS/bin/Debug\net8.0/Module/ChatGPS.psd1
invoke-pester
```

### Ad hoc / manual testing

Once you successfully execute the build step mentioned above you can test resulting PowerShell module build output.

The standard pattern for using the module is to first create a "chat session" context using the `Connect-ChatSession` command,
and then issue a command such as `Send-ChatMessage` to send a single message within the curretn session context
and receive a response:

```powershell

Connect-ChatSession -LocalModelPath /models/Phi-3.5-mini-instruct-onnx/gpu/gpu-int4-awq-block-128
Send-ChatMessage 'Hello!'

Received                 Response
--------                 --------
9/15/2024 3:44:07 PM     Hello there! It's great to have a friendly chat with you. I'm Phi, your conversational
                         companion. I don't have hopes or dreams, but I'm here to help you share yours and make our
                         interaction meaningful. What's on your mind today?
```

In this example, a session was created using a locally hosted model stored at the file system path specified by the `LocalModelPath`
parameter. Additional invocations of `Send-ChatMessage` can be used to continue the conversation with further messages.

The `Start-ChatRepl`

#### Configuring the language model

The module supports the following language models via the `Provider` parameter of `Connect-ChatSession`:

* Azure OpenAI: Specify `AzureOpenAI` to use the [Azure OpenAI service](https://azure.microsoft.com/en-us/products/ai-services/openai-service) which provides access to cloud-hosted large language models such as GPT4.
* Local Onnx: Specify `LocalOnnx` to use a locally hosted model in the [Onnx](https://onnx.ai/) model format. The [Phi 3.5 model](https://azure.microsoft.com/en-us/products/phi/) is an example.
  * This module currently requires the Windows OS for Onnx support, specifically the x64 and arm64 processor architectures.
  * Such models must be [installed to the local file system](https://aka.ms/generatetutorial) in order be used with this module.
  * If you specify the `LocalModelPath` parameter required for this model, you can actually omit the `Provider` parameter

Note that for externally hosted models such as those from Azure OpenAI a credential is required for access via the `ApiKey` parameter,
and because of this, it may be safer to to specify the parameter to the command indirectly so that the secret is not present in command history. Options include:

* Reading the credential from a file stored in a secure location and assigning the file content to a variable, then specifying that variable as the `ApiKey`
  parameter for the `Connect-ChatSession` command
* Reading all parameters for `Connect-ChatSession` from a file stored securely, and piping it into the `Connect-ChatSession` command which accepts all required
  parameters as input from the pipeline. In general you can choose to specify some parameters via the pipeline, and some via the command line.

The latter approach of reading the session parameters from a file and sending them through the pipeline is illustrated below:

```powershell
# Create this file just once
$securelocation = '<your-secure-folder>'
$configfolder = mkdir "$securelocation/chatgpsconfig"
$configpath = "$configfolder/azureopenai.config"

'
{
  "Provider": "AzureOpenAI",
  "ApiEndpoint": "<your-azureopenai-resource-uri>",
  "ModelIdentifier": "<yourmodelname>",
  "ApiKey": "<your-azureopenai-key>"
}
' | Set-Content $configpath


# Create a session using this file below at any time in the future --
# saves typing and keeps sensitive secrets out of command history
Get-Content <your-config-path> | ConvertFrom-Json | Connect-ChatSession
```

#### Use the module

To experience the actual module, you'll need to import it into your session *after you've built it* as described earlier.
The example below uses the `Start-ChatRepl` command to create an interactive chat below -- this is useful for extended
human or automated engagement with the model, as opposed to one-off interactions:

```powershell
cd <your-chatgps-repositoryroot>
import-module ./ChatGPS/bin/Debug\net8.0/Module/ChatGPS.psd1
Get-Content <your-config-path> | ConvertFrom-Json | Connect-ChatSession
Start-ChatRepl # This starts a "Read-Eval-Print-Loop (REPL)" as your interactive chat session
```

If all commands succeed, you should have an interactive prompt that will allow you to interact with the model, e.g.:

```powershell
PS /home/ryu> Start-ChatRepl

(ryu) ChatGPS>: hello


Received                 Response
--------                 --------
9/7/2024 6:37:50 PM      Hello! How can I assist you today?

(ryu) ChatGPS>: Can you tell me which city is known as "The Motor City?"

9/7/2024 6:38:08 PM      Sure! "The Motor City" is a nickname for the city of Detroit, Michigan in the United States.

(ryu) ChatGPS>:
```

To exit the REPL, enter the command `.exit`.

Note that `Send-Chat` and `Start-ChatRepl` contribute to the same session, so you can use one, then switch to the other,
and of course switch again, and the conversation will simply continue.

Whenever you need a fresh or separate conversation session, use `Connect-ChatSession` to create a new session -- specify
the `NoSetCurrent` parameter and save the output of the command in a variable to capture this new session connection. Commands
like `Send-ChatMessage` and `Start-ChatRepl` accept a `Connection` parameter to which this variable can be specified to
support multiple parallel conversations.

## General usage

You can use the `Get-Module` command to see a list of all the commands supported by the module:

```powershell
Get-Module chatgps | Select-Object -ExpandProperty ExportedFunctions
```

License and authors
-------------------
Copyright:: Copyright (c) Adam Edwards

All rights reserved.

