Roadmap for ChatGPS
===================

## To-do items

* Add Unregister-ChatPlugin
* Make session listing hide id by default
* Add timeouts to powershell plugin
* Add progress to powershell plugin
* Start-Shell should show last response even on first run
* Support module reload for plugins
* Add Remove-ChatPlugin global scope or Unregister-ChatPlugin
* Use SessionName instead of Session in commands
* Fix valuefrompipelinebypropertyname scenarios with specific name
* Invoke-ChatFunction, Send-ChatMessage should have allow agent access
* AI grep
* AI Browser
* Make default inputhint part of connection or just a new setting
* Rename InputHint PromptBlock
* Make Start-Chat vs. Start-ChatShell? Wrapper parameters?
* Align UserReplyBlock and ReplyBlock in Send-ChatMessage
* Decide on whether default setting values should be specified in config or modeled explicitly
* Add plugins to connect-chatsession
* Add SendBlock to start-chatshell?
* Add .replay command to re-run list n command
* Add plugins to settings
* Remove SK types from proxy format
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
* Deferred interactive key entry on first message
* Show last error in session connection status
* Last error command for session
* Show current session in list view
* Basic help for start-chatrepl
* VectorDB support
* Remove unneeded PowerShell classes
* Context-aware summarization for code -- it compresses but does not truncate functions or produce inaccurate summary
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

* Plugin: Better metadata, e.g. builtin vs. not
* Plugin: allow plugin type registration by type name
* Encrypted Plugin parameters
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
* Fix session creation to not create a session if it can't connect.
* Make an iplugintable property of ichatservice vs inheritance
* Send session id in hello message
* Aliases for set-chatcurrentsession, etc.
* Rename start-chatrepl to start-chatshell?
* Change block names in start-chatshell (nee start-chatrepl) for consistency with connect-chatsession
* Make connection name part of default prompt if it is available
* Fix receiveblock on startup -- this was actually an issue with userreplyblock, not receiveblock, and it was by design.
* Fix bug where plugins aren't being resent on each request
* .clearhistory command for start-chatshell
* Fix proxy use at startup
* Web plugin
* .showconnection command for start-chatshell
* Add Set-ChatAgentAccess on connection
* Make add-chatplugin create a builder if one is not passed in
* Get rid of multiple plugin.ps1 files
* Add ListAvailable to Get-ChatPlugin
* Change prompt to show connection name
* Make Save-ChatSessionSetting SaveAs reload the new setting
* Rename new-chatplugin to Register-ChatPlugin

### Plugin notes

* Plugin types should be refactored / renamed:
  * PluginInfo -> Plugin
  * Plugin -> PluginProvider
  * \*Plugin -> \*PluginProvider
  * PowerShellKernelPlugin -> PowerShellNativePluginBase

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
  * In the .net library, we provide a base class with a method to invoke a scriptblock based on a function name -- call it B
  * In PowerShell, a class that inherits from that .net class. Call it G
    * It also has an interface for building a type -- this is method T
    * That type is then defined by generating a scriptblock via builder pattern that dynamically defines a class D
      * D has one method for each scriptblock given to it during builder pattern requests.
  * The PowerShellScript plugin inherits from plugin -- call it P
    * It takes as a parameter an instance of G
    * It invokes G=>T to get an object instance to register with the kernel
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
