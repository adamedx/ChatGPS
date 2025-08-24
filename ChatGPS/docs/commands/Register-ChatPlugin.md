---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Register-ChatPlugin

## SYNOPSIS
Registers a new user created chat plugin using PowerShell script code and makes it available for use with sessions through Add-ChatPlugin and related commands.

## SYNTAX

```
Register-ChatPlugin [-Name] <String> [[-Description] <String>] -Function <PowerShellPluginFunction>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Register-ChatPlugin allows users to define new chat plugins and make them available for use in chat sessions; the language model can use the plugin, which contains PowerShell Script Block code that you provide, to direct ChatGPS to execute those script blocks to supply information to the language model or perform actions on the computer system according to instructions from the language model.
For instance you could create a plugin that uses a PowerShell Script Block to return the list of operating system updates applied to the computer in a given time period; once added to a session, that plugin can be utilized to answer the user's conversational queries about such updates.

ChatGPS provides several built-in plugins from Semantic Kernel, and Register-ChatPlugin enables you to define any number of custom plugins with arbitrary functionality implemented as PowerShell code.
Once registered, these custom plugins behave in almost all ways just like the built-in plugins in that they can be added to any session with Add-ChatPlugin or Connect-ChatSession, configured for a session using ChatGPS session settings, and enumerated through the Get-ChatPlugin -ListAvailable command.
For more details on chat plugins and the features they provide, see the documentation for Add-ChatPlugin.

Chat plugins are defined as a collection of one or more plugin functions, and to create a plugin with Register-ChatPlugin, you must supply a collection of plugin functions created by the Add-ChatPluginFunction command; Add-ChatPluginFunction enables you to create a plugin function from a PowerShell Script Block.
Register-ChatPlugin can accept any number of plugin functions created by the Add-ChatPluginFunction through the pipeline as a way to specify the collection.

Once a plugin is registered, it cannot be changed in any way.
However it can be unregistered using the Unregister-ChatPlugin command.
A new plugin with the name of the originally registered plugin can then be registered with Register-ChatPlugin as a way of "re-registering" the plugin.

If a given session's configuration is saved through the Save-ChatSessionSetting comand and that session has a custom plugin registered through Register-ChatPlugin, the session configuration will include the definition of the plugin.
When the configuration is initialized in the future (e.g.
when the ChatGPS module is loaded), the session will be re-registered and can be used just as it can immediately after the invocation of Register-ChatPlugin.
This makes it easy to define such plugins just once and use them on an ongoing basis.

Currently plugins defined by Register-ChatPlugin do not accept initialization parameters like some of the built-in plugins do.

## EXAMPLES

### EXAMPLE 1
```
Add-ChatPluginFunction system_uptime { Get-Uptime } -Description 'Retrieve the uptime of the operating system' |
  Register-ChatPlugin system_basic_information -Description 'Returns basic information about the operating system'
 
Name                           Desciption                                           Parameters
----                           ----------                                           ----------
system_basic_information       Returns basic information about the operating system
 
PS > Add-ChatPlugin system_basic_information
PS > Set-ChatAgentAccess -Allowed # Only needed if this wasn't already done
PS > Send-ChatMessage 'what is the system uptime?'
 
The system uptime is currently 5 days, 0 hours, 34 minutes, and 0 seconds.
 
PS > Get-Uptime | Select-Object Days, Hours, Minutes
 
Days Hours Minutes
---- ----- -------
   5     0      34
```

In this example, Register-ChatPlugin creates a new plugin called system_basic_information from a single chat function piped to it as input; this function simply returns the output of the Get-Uptime command.
After the plugin is registered, the Add-ChatPlugin command must still be used to add it to a session (in this case the current session).
The subsequent invocation of Send-ChatMessage returns a response from the language model with a friendly description, and its output can be compared with that of the next command invocation which actually executes Get-Uptime interactively in the shell.
Note that both the response from Send-Message and invocatio of Get-Uptime return the same information, indicating that the language model did indeed choose the system_uptime function for invocation and its output was used successfully to generate the final response from the language model.

### EXAMPLE 2
```
Add-ChatPluginFunction system_uptime { Get-Uptime } -Description 'Retrieve the uptime of the operating system' |
  Add-ChatPluginFunction get_system_updates  {
      param ([int]$Days = 30) Get-HotFix | Where-Object { $_.InstalledOn -gt (Get-Date).AddDays(-$Days) }
  } -Description 'Returns the list of operating system updates applied to the system in the last N days' |
  Register-ChatPlugin system_basic_information -Description 'Returns basic information about the operating system'
 
Name                           Desciption                                           Parameters
----                           ----------                                           ----------
system_basic_information       Returns basic information about the operating system
 
PS > Add-ChatPlugin system_basic_information
PS > Set-ChatAgentAccess -Allowed # Only needed if this wasn't already done
PS > Start-ChatShell
 
(ryu-azure) ChatGPS>: What operating system updates were applied in the last 45 days?
 
Received                 Response
--------                 --------
7/12/2025 8:26:48 PM     In the last 45 days, the following operating system updates were applied:
 
                         1. **Description**: Security Update
                            **HotFixID**: KB5062553
                            **Installed By**: NT AUTHORITY\SYSTEM
                            **Installed On**: July 8, 2025
 
                         2. **Description**: Update
                            **HotFixID**: KB5062862
                            **Installed By**: NT AUTHORITY\SYSTEM
                            **Installed On**: June 28, 2025
 
                         3. **Description**: Security Update
                            **HotFixID**: KB5063666
                            **Installed By**: NT AUTHORITY\SYSTEM
                            **Installed On**: July 8, 2025
 
                         Let me know if you need more information!
 
(ryu-azure) ChatGPS>: What is the system uptime?
 
7/12/2025 8:34:52 PM     The system uptime is 5 days, 1 hour, 17 minutes, and 52 seconds.
 
In this example, two plugin functions are defined with Add-ChatPluginFunction, and the invocations of Add-ChatPluginFunction are chained together. The second function  In this way, multiple plugin functions can be defined with Add-ChatPluginFunction with a final result where all functions in the pipeline are piped to Register-ChatPluginFunction. After the newly registered plugin is added to the current session through Add-ChatPlugin, Start-ChatShell is used to enter a chat loop, and questions involving both plugin functions in the plugin, one which obtains recent operating system updates, and another which retrieves system uptime, are successfully invoked from the user's natural language queries.
```

### EXAMPLE 3
```
Add-ChatPluginFunction system_uptime { Get-Uptime } -Description 'Retrieve the uptime of the operating system' |
  Register-ChatPlugin system_basic_information -Description 'Returns basic information about the operating system' | out-null
PS > Get-ChatPlugin -ListAvailable
 
Name                           Desciption                               Parameters
----                           ----------                               ----------
Bing                           Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                               the following search engine source: Bing
ConversationSummaryPlugin      Summarizes a conversation.
DocumentPlugin                 Enables the ability to read the
                               contents of Microsoft Word documents in
                               the local file system
FileIOPlugin                   Enables read and write access to the
                               local file system.
Google                         Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                               the following search engine source:
                               Google
HttpPlugin                     Enables the local computer to access
                               local and remote resources via http
                               protocol requests.
SearchUrlPlugin                Computes the search url for popular
                               websites.
system_basic_information       Returns basic information about the
                               operating system
TextPlugin                     Allows the local computer to perform
                               string manipulations.
TimePlugin                     Uses the local computer to obtain the
                               current time.
 
In this example the Get-ChatPlugin -ListAvailable command is invoked after the system_basic_information plugin is registered, and it can be seen in the list of plugins along with the other built-in plugins that are registered by default.
```

## PARAMETERS

### -Name
The name under which chat plugin should be registered.
This name must be unique, i.e.
there must be no existing plugin registered by the value assigned to Name.
When adding this plugin to a session using the Add-ChatPlugin command, the name parameter is given to specify the registered plugin to add to the session.
Note that the plugin's LLM integration may use the name to help the LLM understand the plugin's purpose so that it can decide when to use it, so while an arbitrary plugin will be accepted, the plugin will be most likely to be invoked correctly if the name reflects its purpose.
Note that it is a common convention to use snake case for the name of the plugin because language models have historically been trained to interpret snake case code.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
An optional detailed description of the plugin's purpose.
The description is used by the language model to decide when to use the plugin, and helps differentiate it from other plugins that may seem to to have similar capabilities when only the plugin's name is considered.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Function
A plugin function created by the Add-ChatPluginFunction command.
The plugin function encapsulates a PowerShell Script Block that can be executed to perform a function requested by the language model.
The plugin function's name, description, and other information are used by language models to determine when to invoke the function.
Note that this parameter receives pipeline input, so use the pipeline to to specify more than one plugin function for the plugin.

```yaml
Type: PowerShellPluginFunction
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
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

### Information about the registered plugin, including its name and description.
## NOTES

## RELATED LINKS

[Add-ChatPluginFunction
Add-ChatPlugin
Get-ChatPlugin
Unregister-ChatPlugin
Save-ChatSessionSetting]()

