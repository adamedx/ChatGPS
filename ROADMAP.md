Roadmap for ChatGPS
===================

## To-do items

* Show-ChatHistory command
* Connection management: Get-ChatSession, Remove-ChatSession
* Additional model providers
* SecureString parameters
* Response duration output
* Make an official config file support multiple entries and a default
* Add types to function parameters
* Provide a type for function output
* Non-repl: Include command history in context
* Non-repl: Include command output in context
* Support json schema for function output: https://github.com/microsoft/semantic-kernel/blob/main/dotnet/src/SemanticKernel.Abstractions/Functions/KernelJsonSchema.cs
* Structured output: https://learn.microsoft.com/en-us/dotnet/api/microsoft.semantickernel.connectors.openai.openaipromptexecutionsettings.responseformat?view=semantic-kernel-dotnet#microsoft-semantickernel-connectors-openai-openaipromptexecutionsettings-responseformat
* Plugin creation
* Skill creation
* Planner definition
* Plugin management
* Built-in plugins
* Multi-model support
* Model provisioning
  * Service-based
  * Local
* Languages beyond PowerShell?

## Completed items

* Function definition
* Function invocation
* Function deletion
* Function enumeration
* Generalize function invocation for function chats vs. pure functions
* Generate ps functions from chat functions
* Add auto-complete for chat functions
* Remove semantic kernel's ChatHistory and ChatMessageContent types from public interfaces
