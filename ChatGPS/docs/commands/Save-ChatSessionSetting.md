---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Save-ChatSessionSetting

## SYNOPSIS
Saves the current configuration of a chat session to the settings configuration file.

## SYNTAX

### name
```
Save-ChatSessionSetting [-Name] <String> [-SaveAs <String>] [-ProfileName <String>]
 [-SettingsFilePath <String>] [-NoCreateProfile] [-NoSetDefaultProfile] [-DefaultSession] [-NoNewFile]
 [-NoWrite] [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### id
```
Save-ChatSessionSetting -Id <Guid> [-ProfileName <String>] [-SettingsFilePath <String>] [-NoCreateProfile]
 [-NoSetDefaultProfile] [-DefaultSession] [-NoNewFile] [-NoWrite] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### current
```
Save-ChatSessionSetting [-Current] [-SaveAs <String>] [-ProfileName <String>] [-SettingsFilePath <String>]
 [-NoCreateProfile] [-NoSetDefaultProfile] [-DefaultSession] [-NoNewFile] [-NoWrite] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Save-ChatSessionSetting command saves the configuration values of a given session to the settings configuration file; the saved state will represent the values returned by the Get-ChatSession command for that session.
By saving this information to the file, the session will be available as soon as the ChatGPS module is imported into any PowerShell session, thus preserving the session for us across PowerShell sessions and operating system reboots.
The Save-ChatSessionSetting command offers a convenient alternative to manually editing the configuration file as it can be used with no knowledge of the structure and format of the configuration file.

For more details about settings configuration see the documentation for the New-ChatSettings command.

By default, if there is no settings configuration file, Save-ChatSessionSetting will create a new settings file before saving the session information in the file so that the user does not need to remember to invoke the New-ChatSessionSettings command to explicitly create the file.

All information required for the session to be functional when starting a new PowerShell session is saved to the file.
On the Windows operating system platform, this includes sensitive data including API keys; such parameters are encrypted when they are written to the file using the Get-ChatEncryptedUnicodeKeyCredential.
See the documentation for that command and New-ChatSettingsInfo for details on the conditions in which such data stored in the file can be decrypted.
On platforms other than Windows, these API key settings are not saved.

## EXAMPLES

### EXAMPLE 1
```
Save-ChatSessionSetting -Current
```

This saves the current session to the configuration file.

### EXAMPLE 2
```
Save-ChatSessionSetting azure-gpt4
```

This example shows how to save a chat session by specifying the session's name.

### EXAMPLE 3
```
Save-ChatSessionSetting -Current -SaveAs azure-backup
```

In this example the current session is copied to another session configuration named "azure-backup".

### EXAMPLE 4
```
Get-ChatSession | Where-Object Name -like *azure* | Save-ChatSessionSetting
```

In this example, all sessions with the string 'azure' in the name are enumerated and then piped to Save-ChatSessionSetting to save all such sessions.
The Id parameter of Save-ChatSessionSetting is used to pass the sessions to the pipeline.

## PARAMETERS

### -Name
The name of the chat session to save; this is the same name that shows for the session when Get-ChatSession is used.
If the session does not have a name, or if the session's identifier is already known, the Id parameter can be used instead of the name to choose the session to save.

```yaml
Type: String
Parameter Sets: name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
The session id of the session to save.
Unlike the use of the Name parameter, all sessions have an Id property, so this can always be used to identify a session.
The value can be read from the pipeline, allowing multiple sessions to be piped to the command in order to save those sessions.

```yaml
Type: Guid
Parameter Sets: id
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Current
Specify this parameter to choose to save the current session; this makes it easy to save the current session without needing to identify the name or Id of the session.

```yaml
Type: SwitchParameter
Parameter Sets: current
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SaveAs
Specify a new session name to SaveAs to save the session to a new session setting.
The saved setting will have a name property that is the same as the value of this parameter.
This essentially "copies" the session being saved to a new session setting.
It also has the side effect of immediately creating a new chat session as if Connect-ChatSession had been executed for the setting; a session with the name specified to the SaveAs parameter will be displayed if the Get-ChatSession command is invoked after SaveAs is used to save a setting.

```yaml
Type: String
Parameter Sets: name, current
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileName
Specify ProfileName to set the default session of the specified profile.
By default, the session information is saved but no profile information is changed unless there is no profile in the configuration file, in which case that default profile is created and set to use the session being saved as its default session.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SettingsFilePath
Specify SettingsFilePath to write the settings information to a file system path other than the default settings configuration file at ~/.chatgps/settings.json.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoCreateProfile
Specify NoCreateProfile to avoid creating a profile.
By default, if there is no profile in the settings file, a profile will be created and the saved session will be set as the default session for the profile.

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

### -NoSetDefaultProfile
By default, if there is no default profile, the new profile is created unless the NoCreateProfile parameter is specified.
Use the NoSetDefaultProfile parameter to ensure that the default profile is not configured with the session being saved under any circumstances.

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

### -DefaultSession
{{ Fill DefaultSession Description }}

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

### -NoNewFile
{{ Fill NoNewFile Description }}

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
Specify NoWrite to avoid writing a file; instead, the deserialized form of the settings will be returned.
This is useful if you intend to programmatically manage the settings or use a store other than the file system such as a cloud storage service, or if you want to inspect the changes that would be made by the command.

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
By default, if the SettingsFilePath parameter is specified and the file it references already exists, the command will fail in order to avoid overwriting data in an existing file.
Specify Force to override this safety feature and write the data to the file.

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

### By default, the command does not return output. However if the NoWrite parameter is specified a deserialized object corresponding to the saved session information; this object can be serialized as JSON and inserted in to the settings file through manual editing or automation.
## NOTES

## RELATED LINKS

[Get-ChatSession
New-ChatSessionSettings
Get-ChatSettingsInfo
Update-ChatSettings]()

