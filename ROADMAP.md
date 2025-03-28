Roadmap for ChatGPS
===================

## To-do items

* Agent concept
* Type format for plugins
* Logging (OpenTelemetry)
* Friendly domain-specified log view
* Functions must specify plugins or use session plugins
* Plugin support for functions
* Use PowerShell commands as kernel plugins
* Implement internal connect-chatsession, use it to create new sessions
* Use chat session id as configuration value
* Add Force flag to Update-ChatSettings
* List and set profiles
* Plugins and associated settings
* Internet search
* assistant mode
* Tutorial mode
* Update-ChatSettings -- validate only
* Update-ChatSettings -- nosetcurrent
* Voice management (Remove-ChatVoice)?
* Voice settings?
* Send session id in hello message
* Deferred interactive key entry on first message
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
* Docs
* Samples
* Add embedding support
* Better error messages for local model platform support, move to chatsession and chat service interface
* Add types to function parameters
* Provide a type for function output
* Normal powershell functions defined by natural language
* NL chat
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
* Invoke-ChatFunction should take a definition
* Additional model providers
* Make an official config file support multiple entries and a default
* Remove SessionFunctions, remove function methods from ChatSession
* Add other Connect-ChatSession options such as summarization and history limit to settings
* Show history context limit in session output
* Connection Save
* New-Settings
* Contributing
* Code of conduct
* License
* Remove session affinity for chat functions!
* Aliases for set-chatcurrentsession, etc.
* Show current session in list view

### Plugin notes

* There should be commands that list plugins from different sources
* The sources should include built-in supplied by Semantic Kernel, some supplied with Chat GPS, and user defined
* You should be able to create your own plugins that execute powershell code
* Some plugins will not be compatible with proxy mode
* Should have diagnostic commands to assess capabilities of the model
* User-defined plugins should be their own config section
* Change chat protocol to enable / disable function calling
* Send-ChatCommand should have a parameter to control calling
* Function calling should be a session option but overrideable
* Session should be able to disable / enable function calling
* Can plugins be removed?
* Maybe use profiles to switch between sets of plugins?
* PowerShell plugins will need to be a single type, but initialized from different objects
* Plugins need to be serialized with the session.
* New custom plugins -- try to build with powershell
  * ShellInfo -- can have read-write mode
    * Tells you the current location
    * lets you tell it to cd
    * should work with bash
    * can read / write files
    * can enumerate files
    * can read / set environment variables
    * can read command history
    * can read powershell variables
    * uses powershell host
