Roadmap for ChatGPS
===================

## To-do items

* Send session id in hello message
* Remove SessionFunctions, remove function methods from ChatSession
* Show last error in session connection status
* Last error command for session
* Aliases for set-chatcurrentsession, etc.
* Show current session in list view
* Basic help for start-chatrepl
* Rename start-chatrepl to start-chatshell?
* VectorDB support
* Remove unneeded PowerShell classes
* Context-aware summarization for code -- it compresses but does not truncate functions or produce inaccurate summary
* Fix session creation to not create a session if it can't connect.
* Command to trigger re-auth?
* Generalize tokenlimit handling across services
* Last error for session
* Configure user agent
* Include the current sent time in all responses.
* Self-help
* Pull request template
* Contributing
* Code of conduct
* License
* Docs
* Samples
* Add embedding support
* Better error messages for local model platform support, move to chatsession and chat service interface
* Additional model providers
* Make an official config file support multiple entries and a default
* Add types to function parameters
* Provide a type for function output
* Normal powershell functions defined by natural language
* NL chat
* Invoke-ChatFunction should take a definition
* Non-repl: Include command history in context
* Non-repl: Include command output in context
* Support json schema for function output: https://github.com/microsoft/semantic-kernel/blob/main/dotnet/src/SemanticKernel.Abstractions/Functions/KernelJsonSchema.cs
* Structured output: https://learn.microsoft.com/en-us/dotnet/api/microsoft.semantickernel.connectors.openai.openaipromptexecutionsettings.responseformat?view=semantic-kernel-dotnet#microsoft-semantickernel-connectors-openai-openaipromptexecutionsettings-responseformat
* Plugin creation
* Skill creation
* Planner definition
* Plugin management
* Built-in plugins
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
* Multi-model support
* Remove semantic kernel's ChatHistory and ChatMessageContent types from public interfaces
* Response duration output
* Get-ChatHistory command
* Fix throttling errors not propagating in proxy mode
* Custom system prompt
* Standardize on naming of Session instead of Connection
* include signin status (has access been validated)
* Delegated auth for Azure
* include signin info, e.g. interactive or not.
* Enable CI pipeline
* Fix system prompt time stamp
* Add preprocess and postprocess scriptblocks to connection that take input as a parameter
* Add zero context scenario (or N lines of latest context) for sending context to the model
* Contributing
* Code of conduct
* License
* Remove session affinity for chat functions!
* Examples for receive and sendblocks
* Change block names in start-chatrepl for consistency with connect-chatsession
* Move function prompt out of session context
* Redesign function prompts
* Add function to start-chatrepl
* publish local module
* Include user agent
* Configuration file at startup
* Encrypt api keys
* Session names
* Connection management: Get-ChatSession, Remove-ChatSession
* Add progress during connection test
