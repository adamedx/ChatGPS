---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# New-ChatSettings

## SYNOPSIS
Creates a new ChatGPS configuration settings file in the local file system.

## SYNTAX

```
New-ChatSettings [[-SettingsFilePath] <String>] [-ProfileName <String>] [-PassThru] [-NoSession] [-NoWrite]
 [-NoProfile] [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ChatGPS module provides a configuration settings mechanism, including a file for specifying setings, that controls default behaviors of module commands, location and credentials required to access language models, plugins that grant models access to local and other user resources, and chat session use of models.
The New-ChatSettings command creates the file that contains the settings.

By default, no settings file exists for the ChatGPS module; the file must be created explicitly by the New-ChatSettings command, or by invoking the Save-ChatSetting command which will create a file if it doesn't exist in order to save session setting information.

The default location of the settings file is ~/.chatgps/settings.json -- when New-ChatSettings is invoked with no parameters it will attempt to create the file in this location.
Alternatively, the SettingsFilePath parameter may be specified to create a new settings file in a different location.
Note that if a file already exists at whatever location is targeted by New-ChatSettings, the command will fail and will not alter the existing file; the Force parameter may be specified to force an overwrite of the existing file.

Settings in the file are applied when the module is loaded, and can be re-applied using the Update-ChatSettings command.
You can disable settings application at module load by configuring the environment variable CHATGPS_SKIP_SETTINGS_ON_LOAD with the value 'true' before importing the module.

Settings application is best effort; ChatGPS will attempt to apply various settings for sessions and plugins for instance, and will skip individual settings that are incorrectly specified or encounter errors of some sort, with the goal of applying other settings that are applied correctly.
A corrupt file however can cause a total failure to apply any settings.

Some setting values stored in the file may be sensitive, such as API keys for accessing language models; these values are assumed to be encrypted by the Get-ChatEncryptedUnicodeKeyCredential command, though this capability is only supported on the Windows platform.
Such values may only be decrypted by the user who originally encrypted the setting and only on the same computer on which it was encrypted, which means that if the configuration file is copied to another computer the configuration value will be invalid.
If encryption is not available on the platform or the risk tradeoff of unauthorized decryption is too significant, leave such values unspecified in the settings file and allow prompting for the setting or obtain it securely at runtime and use an imperative command such as Connect-ChatSession to configure it as needed.

The format of the file is JSON; it may be edited manually through a text editor or other JSON editing tools, but the simplest way to modify it is through the Save-ChatSessionSetting command.

The file has the following logical structure:

* defaultProfile: this is a global setting indicating the profile from which settings should be applied
* profiles: This section contains an element called list which is an array of profiles.
Currently profiles have a name element which specifies the name of the profile, and this name value is what must be configured as the value for defaultProfile for the settings linked to a profile to be applied.
The other element of profile is SessionName, which indicates which session from the sessions element should be set as the current session.
* sessions: This section contains an element called list which is an array of sessions that model chat sessions created by Connect-ChatSession.
Sessions essentially contains the values of the parameters for the Connect-ChatSession command, allowing you to declaratively specify sessions that should be created when the profile is applied rather than requiring that you imperatively execute several Connect-ChatSession commands with the NoConnect parameter.
Every session must have a name element that uniquely identifies it as well as a modelName element specifying information about the language model used for the chat session.
Sessions may also reference a list of plugins that should be configured, just as Connect-ChatSession allows for session configuration.
These plugins may be custom plugins defined by Register-ChatPlugin, but those plugin definitions must be included in the customPlugins section of the settings file.
There is also a defaults element of sessions which contains some default values to be applied to all sessions unless overridden explicitly by a session element.
* models: The models contains an element called list which is an array of models that describe language models for use in a chat session created by Connect-ChatSession.
Each model element roughly contains values that map to the parameters of Connect-ChatSession that specify the language model, such as the URI for accessing the model, deployment information, and credentials, which are encrypted.
The defaults element of models contains default values for all models for options such as token limits.
* customPlugins: This section defines plugins defined through the Register-ChatPlugin command.
It contains a list element which is an array of plugin elements that roughly correspond to the arguments of Add-ChatPluginFunction and Register-ChatPlugin for defining custom plugins.

## EXAMPLES

### EXAMPLE 1
```
New-ChatSettings
```

This creates a new settings file at the default settings path of ~/.chatgps/settings.json

### EXAMPLE 2
```
New-ChatSettings -SettingsFilePath ~/Documents/localchatgp-settings.json
```

This example shows how the New-ChatSettings command can be used to create a settings file at an arbitrary path using the SettingsFilePath parameter.

### EXAMPLE 3
```
$settings = New-ChatSettings -NoWrite
$settings
 
generatedDate   : 7/13/2025 12:45:02 PM -04:00
generatedTool   : ChatGPS New-ChatSettings
lastUpdatedDate :
lastUpdatedTool :
defaultProfile  : Profile0
profiles        : ProfileSettings
sessions        : SessionSettings
models          : ModelResourceSettings
customPlugins   : CustomPluginResourceSettings
```

This example shows how to store the settings as an object assigned to a variable without writing anything to disk.
In this example the settings data is output to the console so it can be inspected.
Assigning the data to a value allows automated modification of the settings, which can later be serialized to the file system or in some other external storage location and managed through another application or system if needed.

## PARAMETERS

### -SettingsFilePath
An optional path at which to generate the new settings file.
When this parameter is not specified, the file is created at the default path, ~/.chatgps/settings.json.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileName
{{ Fill ProfileName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Profile0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
By default, the command does not return output; specify PassThru to return a deserialized object equivalent to the content of the generated JSON settings file.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoSession
By default, the command will generate placeholder session and model values -- specify this parameter to skip this behavior.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoWrite
Specify NoWrite to avoid writing a file; instead, the deserialized form of the settings will be returned as output as it would be if PassThru were specified.
This is useful if you intend to programmatically manage the settings or use a store other than the file system such as a cloud storage service.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProfile
{{ Fill NoProfile Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
By default, New-ChatSettings will fail if it the settings file it attempts to write to already exists; this behavior exists to avoid accidentally erasing data.
Specify Force so that if the file already exists, it will be overwritten by the command.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
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

### By default, the command does not return output unless the NoWrite or PassThru parameters are specified. In those cases, a deserialized object corresponding to the new settings is returned; that object could be serialized as JSON and would yield a valid settings configuration file.
## NOTES

## RELATED LINKS

[Save-ChatSessionSetting
Get-ChatSettingsInfo
Update-ChatSettings]()

