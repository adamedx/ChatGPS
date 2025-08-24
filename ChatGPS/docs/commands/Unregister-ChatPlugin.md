---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Unregister-ChatPlugin

## SYNOPSIS
Unregisters a custom chat plugin created by Register-ChatPlugin.

## SYNTAX

### byname
```
Unregister-ChatPlugin [-Name] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### byobject
```
Unregister-ChatPlugin -Plugin <PowerShellPluginProvider> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Register-ChatPlugin allows users to define new chat plugins and make them available for use in chat sessions.
This operation can be undone by the Unregister-ChatPlugin command.
Once Unregister-ChatPlugin is successfully invoked for a given plugin, the plugin will no longer be available to be added to sessions through the Add-ChatPlugin or Connect-ChatSession commands.

Note that any sessions using a plugin that is unregistered by Unregister-ChatPlugin will be unaffected -- they will still be able to use the previously registered plugin; Unregister-ChatPlagin merely removes the ability to add the plugin to sessions that do not already have it added.

If a plugin is unregistered, a new plugin with the same name as the unregistered plugin can then be registered via Register-ChatPlugin.

The ability to unregister a plugin can be particularly useful when you want to redefine a plugin since Register-ChatPlugin does not allow plugins to be modified after registration.
For example, if you realize that you could improve the plugin's description so that the language model makes better choices about when to use the plugin, you can unregister it, then register it again with the modified description, and the improved plugin can be added to sessions.
Other improvements to the plugin, such as improvements to its code, can also be made.

If a built-in plugin is supplied to Unregister-ChatPlugin, the command will fail as only custom plugins registered by Register-ChatPlugin can be unregistered.

## EXAMPLES

### EXAMPLE 1
```
Unregister-ChatPlugin system_basic_information
```

This example unregisters a plugin named system_basic_information.

### EXAMPLE 2
```
Get-ChatPlugin -ListAvailable | Where-Object IsCustom  | Measure-Object | Select-Object Count
 
Count
-----
3
 
PS > Get-ChatPlugin -ListAvailable | Where-Object IsCustom | Unregister-ChatPlugin
PS > Get-ChatPlugin -ListAvailable | Where-Object IsCustom  | Measure-Object | Select-Object Count
 
Count
-----
    0
 
In this example, we first enumerate the custom plugins using Get-ChatPlugin -ListAvailable piped to Where-Object to filter them to just the custom plugins, i.e. those created by Register-ChatPlugin, by using the IsCustom property. We count these and find there are 3 of them. We then execute a similar command, but this time instead of piping the custom plugins to Measure-Object for counting, we pipe them to Unregister-ChatPlugin to all custom plugins. We then verify the result by re-running the first command, which returns a result of 0 custom plugins as expected.
```

## PARAMETERS

### -Name
The name of the plugin to unregister.
The name corresponds to the plugin's name as found in the enumeration of available plugins from Get-ChatPlugin -ListAvailable.

```yaml
Type: String
Parameter Sets: byname
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Plugin
A plugin object returned from Register-ChatPlugin or Get-ChatPlugin -ListAvailable.

```yaml
Type: PowerShellPluginProvider
Parameter Sets: byobject
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

### None.
## NOTES

## RELATED LINKS

[Register-ChatPlugin
Get-ChatPlugin]()

