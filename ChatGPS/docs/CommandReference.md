Command Reference
=================

|[Documentation Home](Introduction.md)|
|-------------------------------------|

|Command|Description|
|-------|-----------|
|[Add-ChatPlugin](commands/Add-ChatPlugin)|Configures a session to use the specified chat plugin to execute code locally during language model interactions.|
 |[Add-ChatPluginFunction](commands/Add-ChatPluginFunction)|Adds a plugin function to an existing collection of plugins sent to the pipeline.|
 |[Build-ChatCode](commands/Build-ChatCode)|Generates (builds) programming language code including PowerShell scripts from a natural language specification. Typically accessed through the Generate-ChatCode alias.|
 |[Clear-ChatConversation](commands/Clear-ChatConversation)|Clears the session's conversation context history.|
 |[Clear-ChatLog](commands/Clear-ChatLog)|Clears the log of the messages exchnaged in the session.|
 |[Connect-ChatSession](commands/Connect-ChatSession)|Creates a new "chat" session between the user and a supported language model. The model may be hosted locally or accessed remotely through a service provider.|
 |[Get-ChatConversation](commands/Get-ChatConversation)|Gets the current conversation context of messages for a chat session interaction with a language model.|
 |[Get-ChatCurrentVoice](commands/Get-ChatCurrentVoice)|Experimental command that obtains the current voice for the chat session.|
 |[Get-ChatEncryptedUnicodeKeyCredential](commands/Get-ChatEncryptedUnicodeKeyCredential)|Encrypts a string using a format that is compatible with PowerShell's Get-Credential command.|
 |[Get-ChatFunction](commands/Get-ChatFunction)|Retrieves all currently chat functions which are functions defined by natural language.|
 |[Get-ChatLog](commands/Get-ChatLog)|Gets the conversation history of messages for a chat session interaction with a language model.|
 |[Get-ChatPlugin](commands/Get-ChatPlugin)|Gets chat plugins associated with a session, or obtains the list of all registered plugins that are available to be added to any session.|
 |[Get-ChatSession](commands/Get-ChatSession)|Gets information about currently defined chat sessions created by Connect-ChatSession or ChatGPS settings configuration.|
 |[Get-ChatSettingsInfo](commands/Get-ChatSettingsInfo)|Gets information about configuration settings for the ChatGPS module, including the location of the settings file.|
 |[Get-ChatVoiceName](commands/Get-ChatVoiceName)|Experimental command that creates a new text-to-speech voice.|
 |[Install-ChatAddOn](commands/Install-ChatAddOn)|Installs add-on components to the ChatGPS module for additional functionality.|
 |[Invoke-ChatFunction](commands/Invoke-ChatFunction)|Executes a "chat" function previously defined by the New-ChatFunction command; a chat function is a parameterized function defined by natural language.|
 |[New-ChatFunction](commands/New-ChatFunction)|Creates a new "chat" function, a parameterized function defined by natural language using Handlebars (https://handlebarsjs.com/) templating syntax.|
 |[New-ChatScriptBlock](commands/New-ChatScriptBlock)|Creates a parameterized PowerShell script block that invokes a chat function created by New-ChatFunction and optionally binds it to a PowerShell function.|
 |[New-ChatSettings](commands/New-ChatSettings)|Creates a new ChatGPS configuration settings file in the local file system.|
 |[New-ChatVoice](commands/New-ChatVoice)|Experimental command that creates a new text-to-speech voice.|
 |[Out-ChatVoice](commands/Out-ChatVoice)|Experimental command that sends output to a text-to-speech engine.|
 |[Register-ChatPlugin](commands/Register-ChatPlugin)|Registers a new user created chat plugin using PowerShell script code and makes it available for use with sessions through Add-ChatPlugin and related commands.|
 |[Remove-ChatFunction](commands/Remove-ChatFunction)|Removes a chat function created by the New-ChatFunction command.|
 |[Remove-ChatPlugin](commands/Remove-ChatPlugin)|Removes a chat plugin associated with a session.|
 |[Remove-ChatSession](commands/Remove-ChatSession)|Removes a chat session from the list of defined chat sessions, rendering it inaccessible and thus unusable.|
 |[Save-ChatSessionSetting](commands/Save-ChatSessionSetting)|Saves the current configuration of a chat session to the settings configuration file.|
 |[Select-ChatSession](commands/Select-ChatSession)|Sets the default 'current' session used by commands that interact with language models when the command does not explicitly specify a session.|
 |[Send-ChatMessage](commands/Send-ChatMessage)|Sends a message with conversation context to a language model and returns the response from the model.|
 |[Set-ChatAgentAccess](commands/Set-ChatAgentAccess)|Configures a chat session to allow or disallow interactions between language models and chat plugins that enable language model interactions with user accessible resources including the local computer system and applications.|
 |[Set-ChatCurrentVoice](commands/Set-ChatCurrentVoice)|Experimental command that creates a new text-to-speech voice.|
 |[Start-ChatShell](commands/Start-ChatShell)|Sends a message with conversation context to a language model and returns the response from the model.|
 |[Unregister-ChatPlugin](commands/Unregister-ChatPlugin)|Unregisters a custom chat plugin created by Register-ChatPlugin.|
 |[Update-ChatSettings](commands/Update-ChatSettings)|Applies the latest configuration settings that are specified in the default configuration file or a specified configuration file.|

