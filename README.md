ChatGPS
=======

**ChatGPS** enhances your interactive and scripted PowerShell sessions with artificial intelligence. With ChatGPS you can:

* Generate PowerShell code from natural language prompts within your PowerShell interactive experience
* Create AI PowerShell functions / commands based on natural language instead of PowerShell code
* Integrate AI into your PowerShell script library
* Get help / "how-to" advice about PowerShell in the context of your existing PowerShell session
* Create AI chatbots, whether purely conversational or focused on a specialization of your choosing
* Automate AI testing of various AI models

ChatGPS allows you to choose the AI model that powers its experience and supports both remotely hosted models such as those provided by Azure OpenAI, Open AI, etc., as well as locally hosted models like Phi3.

ChatGPS is built on [Semantic Kernel (SK)](https://github.com/microsoft/semantic-kernel), and therefore should work well with any models and AI capabilities supported by SK.

# System requirements

* [PowerShell](https://github.com/PowerShell/PowerShell) 7.4 and higher on Windows, Linux, or MacOS
* Models
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

#### Configure a model

Currently only the Azure OpenAI service is supported -- to configure an Azure OpenAI large language model, create a configuration file
that contains your Azure OpenAI model connection information. Because this information includes credentials, you should create this
file in a secure file system location accessible only to you and no other users or applications:

```powershell
$securelocation = '<your-secure-folder>'
$configfolder = mkdir "$securelocation/chatgpsconfig"
$configpath = "$configfolder/azureopenai.config"

'
{
  "ApiEndpoint": "<your-azureopenai-resource-uri>",
  "ModelIdentifier": "<yourmodelname>",
  "ApiKey": "<your-azureopenai-key>"
}
' | out-file $configpath
```

You'll use the file created above to connect ChatGPS to Azure OpenAI.

#### Use the module

To experience the actual module, you'll need to import it into your session *after you've built it* as described earlier:

```powershell
cd <your-chatgps-repositoryroot>
import-module ./ChatGPS/bin/Debug\net8.0/Module/ChatGPS.psd1
Get-Content $configpath | convertfrom-json | Connect-ChatSession
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

## General usage

You can use the `Get-Module` command to see a list of all the commands supported by the module:

```powershell
get-module chatgps | select -ExpandProperty ExportedFunctions
```

License and authors
-------------------
Copyright:: Copyright (c) Adam Edwards

All rights reserved.

