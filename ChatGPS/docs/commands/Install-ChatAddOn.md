---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Install-ChatAddOn

## SYNOPSIS
Installs add-on components to the ChatGPS module for additional functionality.

## SYNTAX

```
Install-ChatAddOn [[-AddOns] <String[]>] [-UsePrivateDotNet] [-PassThru] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
ChatGPS provides access to many aspects of AI language model functionality.
Because some capabilities including local Onnx model inferencing result in large PowerShell module sizes near 100MB, these capabilities are omitted from the ChatGPS PowerShell module published to PowerShell module repositories.
Use the Install-ChatAddOn command to install the missing functionality to the ChatGPS module.

If the AddOn parameter is not specified to the command, then all AddOns are installed.

Currently the only supported add-on is LocalOnnx, which enables the use of local Onnx models.
For more information about local model support, see the Connect-ChatSession command.

Because the functionality is not distributed through a PowerShell repository, the Install-ChatAddOn command will use other tools such as dotnet to obtain the required files from sources such as a nuget repository.
If the tool required to download the capabilities is not available, the command attempts to install that tool as well.

Add-ons only need to be installed once to enable the functionality.
If a failure is encountered during the execution of the command it is typically safe to re-invoke the command to retry.
If the command is successful and the command is invoked again, the command will result in no operation unless the Force parameter is specified.

## EXAMPLES

### EXAMPLE 1
```
Install-ChatAddOn
```

This example installs all add-ons.
Because no add-ons were specified with the AddOns parameter, all supported add-ons were installed.

### EXAMPLE 2
```
Install-ChatAddOn LocalOnnx -PassThru
```

C:\Program Files\dotnet\dotnet.exe

In this case an explicit add-on is specified via the AddOns parameter, and PassThru is used to return the tool used to install the specified AddOn, which in this case was the dotnet tool.

## PARAMETERS

### -AddOns
The add-ons to install.
Currently the only supported add-on is LocalOnnx.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @('LocalOnnx')
Accept pipeline input: False
Accept wildcard characters: False
```

### -UsePrivateDotNet
By default, when the dotnet tools is needed to install an add-on, the existing installed version of the dotnet tool is used if it is present, and a new version of the dotnet tool is not installed unless there is no current version or the current version is very old (pre-dating .Net 8).
Specify this parameter to force installation and use of the dotnet tool even when an existing compatible version is found.

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

### -PassThru
By default, the command returns no output.
Specify PassThru to return the tools (e.g.
PowerShell commands or other command-line tools such as dotnet) used to install the add-on.
This can be useful for debugging installation failures and identifying workarounds.

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
{{ Fill Force Description }}

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

### By default, no output is returned unless the PassThru parameter is specified.
## NOTES

## RELATED LINKS

[Connect-ChatSession]()

