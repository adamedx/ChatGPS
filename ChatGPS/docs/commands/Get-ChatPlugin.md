---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Get-ChatPlugin

## SYNOPSIS
Gets chat plugins associated with a session, or obtains the list of all registered plugins that are available to be added to any session.

## SYNTAX

### byname (Default)
```
Get-ChatPlugin [[-Name] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### listavailable
```
Get-ChatPlugin [[-Name] <String>] [-ListAvailable] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### bynamebysessionname
```
Get-ChatPlugin [-Name] <String> -SessionName <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### bynamebysession
```
Get-ChatPlugin [-Name] <String> -Session <ChatSession> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### bysessionname
```
Get-ChatPlugin -SessionName <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### bysession
```
Get-ChatPlugin -Session <ChatSession> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-ChatPlugin enumerates plugins that enable language model interactions initiated by ChatGPS commands to execute code on the local system.
This allows language models to process information about the local system or other resources to which the user has access.
Plugins also allow the local system to make changes to the local system or other resources accessible to the user, effectively allowing the model to act as an "agent" performing tasks on behalf of the user.
Chat plugins are enabled for a given session, and by default sessions have no plugins, so chat session interactions with the model have no side effects and do not send information to the model beyond what is explicitly sent by the user to the model through ChatGPS commands.

To enable plugins for a session, the plugins must be explicitly specified when the session is created through Connect-ChatSession or settings configuration, or after session creation by using the Add-ChatPlugin command.
Plugins may be removed from a session through the Remove-ChatPlugin command.

When no arguments are specifid, Get-ChatPlugin lists the plugins associated with the current session.
The Name or Id parameters may be specified to return the plugins for a specific session by session name or session id respectively.

Use the ListAvailable parameter to enumerate all registered plugins, i.e.
all possible plugins that could be assigned to any session through the Add-ChatPlugin command or by creating a new session.
By default, ChatGPS supports a list of builtin pre-registered plugins, and additional plugins beyond this set may be registered and unregistered by the user through the Register-Plugin and Unregister-Plugin commands.

## EXAMPLES

### EXAMPLE 1
```
Get-ChatPlugin
 
Name                     Description                              Parameters
----                     -----------                              ----------
Bing                     Enables access to search the web using   apiKey
                         the following search engine source: Bing
FileIOPlugin             Enables read and write access to the
                         local file system.
system_powershell_agent  Uses powershell code to interact with
                         the operating system
TimePlugin               Uses the local computer to obtain the
                         current time.
```

In this example, Get-ChatPlugin with no arguments lists the plugins currently added to the session.


This invocation set the current session to a session named 'CodingSession'.
Subsequent commands that interact with langauge models will use this session unless an override is specified for that particular command.

### EXAMPLE 2
```
Get-ChatPlugin -ListAvailable
 
Name                     Desciption                               Parameters
----                     ----------                               ----------
Bing                     Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                         the following search engine source: Bing
FileIOPlugin             Enables read and write access to the
                         local file system.
Google                   Enables access to search the web using   {apiKey, apiUri, searchEngineId}
                         the following search engine source:
                         Google
HttpPlugin               Enables the local computer to access
                         local and remote resources via http
                         protocol requests.
msgraph_agent            Accesses the Microsoft Graph API
                         service to obtain information from and
                         about the service.
SearchUrlPlugin          Computes the search url for popular
                         websites.
system_powershell_agent  Uses powershell code to interact with
                         the operating system
system_powershell_agent2 Uses powershell code to interact with
                         the operating system
TextPlugin               Allows the local computer to perform
                         string manipulations.
TimePlugin               Uses the local computer to obtain the
                         current time.
WebFileDownloadPlugin    Enables access to web content by
                         downloading it to the local computer.
```

This example uses the ListAvailable option to show all registered plugins.
These plugins are available to be added to a session through the Add-ChatPlugin command, and can also configured through the Connect-ChatSession command or settings configuration.

## PARAMETERS

### -Name
The name of the chat plugin to retrieve.
When ListAvailable is not specified, the command returns a plugin with this name in the current session.
If the ListAvailable flag is specified, then registered plugins that contain the specified value of this parameter in the name are returned, allowing the user to find available plugins related to a particular function specified by Name.

```yaml
Type: String
Parameter Sets: byname, listavailable
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: bynamebysessionname, bynamebysession
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionName
The name property of an existing session for which plugins added to that session should be retrieved.
If neither this nor the Session parameter are specified then plugins are enumerated from the current session.

```yaml
Type: String
Parameter Sets: bynamebysessionname, bysessionname
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session
The session object (as returned by commands such as Get-ChatSession) for which plugins added to that session should be retrieved.
If neither this nor the SessionName parameter are specified then plugins are enumerated from the current session.

```yaml
Type: ChatSession
Parameter Sets: bynamebysession, bysession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ListAvailable
{{ Fill ListAvailable Description }}

```yaml
Type: SwitchParameter
Parameter Sets: listavailable
Aliases:

Required: True
Position: Named
Default value: False
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

### When ListAvailable is not specified, the command returns all plugins added to the specified session, or just the specific plugin identified by the Name parameter. When ListAvailable is specified, the command returns all registered chat plugins, i.e. plugins availalble to be added to any session, and if Name is specified the list is filtered to anything that contains Name.
## NOTES

## RELATED LINKS

[Add-ChatPlugin
Register-ChatPlugin
Remove-ChatPlugin
Unregister-ChatPlugin
Connect-ChatSession]()

