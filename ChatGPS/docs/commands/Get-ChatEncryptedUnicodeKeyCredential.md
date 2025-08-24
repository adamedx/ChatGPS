---
external help file: ChatGPS-help.xml
Module Name: ChatGPS
online version:
schema: 2.0.0
---

# Get-ChatEncryptedUnicodeKeyCredential

## SYNOPSIS
Encrypts a string using a format that is compatible with PowerShell's Get-Credential command.

## SYNTAX

```
Get-ChatEncryptedUnicodeKeyCredential [-PlainText <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-ChatEncryptedUnicodeKeyCredential command encrypts a string so that it can only be decrypted on the same machine on which it was originally encrypted by the same user who encrypted using this command.
The encryption mechanism is the same as that used by the commonly used PowerShell commands Get-Credential, Read-Host -AsSecureString, and ConvertTo-SecureString -AsPlainText commands.

The resulting values returned by this command are useless to software executing on a computer other than the one which executed this command, and even on the same computer users running under a different user account than the one used to invoke this command will not be able to decrypt it.
Therefore the result can be stored in files such as configuration files with relatively low risk.

That said, an attacker who is able to run software on the same computer than ran this command using the same user account (possibly by breaching that user's login credentials to the computer) will be able to decrypt it.
The risk of this breach must be weighed against the utility of storing this encrypted credential in the file system and the importance of the credential itself, i.e.
if the API key for a language model is leaked, how much damage can be done?

Use this command when specifying sensitive values to certain ChatGPS commands or configuration.
The following commands can make use of values created through this command:

* Connect-ChatSession: The ApiKey parameter is required for models that use an API key for access.
Connect-ChatSession assumes the key provided for this parameter is encrypted using the format produced by Get-ChatEncryptedUnicodeKeyCredential, so use this command when the value must be specified on the command-line.
* Similarly when specifying the equivalent apiKey property in the ChatGPS settings file (see the Get-ChatSettingsInfo command for more details), the actual value must be encrypted using this command (or one that produces the same result).
When writing settings designated as encrypted such as API keys, the Save-ChatSessionSetting command will always write the values using this encrypted format.
* Some chat plugins configurable via the Add-ChatPlugin command support encrypted parameters.
For such parameters (for example in the case of the Bing plugin's apiKey parameter), the value must be specified using the Get-ChatEncryptedUInicodeKeyCredential command or an equivalent.

Get-ChatEncryptedUnicodeKeyCredential when invoked with no arguments uses PowerShell's built-in Read-Host command with the -AsSecureString parameter to securely read the string from the terminal and store it in memory in an encrypted form.
A less secure option is to specify the command with the PlainText parameter which then returns it in an encrypted form.
The latter option is particularly useful if the plain text data is already available in a file or environment variable since it can be accessed programmatically and passed to the Get-ChatEncryptedUnicodeKeyCredential command without displaying it on a screen or copying it into a clipboard where it may be unintentionally copied to an insecure location or otherwise left accessible to other software or users on the system.

The value returned by this command will be in the form of a string that is a textual representation of 16-bit hexadecimal values that can be converted to a Unicode stringstill encrypted of course).
The value will look something like the following:

01000000d08c9ddf0115d1118c7a00c04fc297eb010000001444b757d29ec847a8000486756b0fc20000000002000000000010660000000100002000000039dba7760dbb2fd571beebea954cc0095063cf2e474457239d3b1d79b88fd6ef000000000e80000000020000200000007ac3dd9d258b00831669e2798fe7cd2c596a5d33b01023122badbb1a9a41756120000000cc4b9c7d99ecd8226d64652487760ab0414875887d3b84733a8cc9bb892aeced40000000dfdb3826720f5835713eef7f61d7419b8048efc579d479c10366c2d59f6752b6ae732bcd0beb494dcfd3a5356963964e573272d4bdd2001997ec05bdfc507200

Note that this command is currently only supported on Windows as .NET does not currently implement the functionality for its ProtectData class on platforms other than Windows.
The Windows implementation is based on the CryptProtectData APIs.

## EXAMPLES

### EXAMPLE 1
```
$encryptedApiKey = Get-ChatEncryptedUnicodeKeyCredential
ChatGPS: Enter secret key / password>: *****************************
 
PS > Connect-ChatSession -Apiendpoint 'https://ryu-2025-07.openai.azure.com' -DeploymentName gpt4-1  -ApiKey $encryptedApiKey
```

In this example, Get-ChatEncryptedUnicodeKeyCredential is used to obtain an encrypted API key value by reading securely from the terminal.
The encrypted value is then provided to the Connect-ChatSession command executing on the same computer with the same user account, and therefore it can decrypt the value and use it to access the language model.

### EXAMPLE 2
```
$encryptedApiKey = Get-AzKeyVaultSecret -VaultName LLMVault -Name gpt41-ryu -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > Connect-ChatSession -Apiendpoint 'https://ryu-2025-07.openai.azure.com' -DeploymentName gpt4-1  -ApiKey $encryptedApiKey
```

In this example, the plaintext value of a API key is read from its secure storage location in an Azure KeyVault resource using the Get-AzKeyuVaultSecret command.
The value is piped to Get-ChatEncryptedUnicodeKeyCredential, which re-encrypts the value which is then assigned to a variable.
The variable is then used with the ApiKey parameter of the Connect-ChatSession command to securely connect to the language model.

### EXAMPLE 3
```
$encryptedBingApiKey = Get-AzKeyVaultSecret -VaultName Bing -Name SearchApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
PS > Add-ChatPlugin -PluginName Bing -ParameterNames apiKey -ParameterValues $encryptedBingApiKey
```

This example shows how to specify encrypted parameters to chat plugins that require encryption for some parameters.
In this case, the Bing plugin requires an API key, and as in the previous example, the key is obtained from a secure Azure KeyVault resource, and then encrypted with Get-ChatEncryptedUnicodeKeyCredential such that ChatGPS commands can decrypt it at the time the plugin needs to use the key to access Bing.

## PARAMETERS

### -PlainText
Specifies unencrypted text.
If this parameter is specified, the command returns an encrypted version of the unencrypted text.
If this parameter is not specified, then the user is asked to provide the data to encrypt by secure interactive input into the terminal.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### A string of characters representing the data provided to the command in an encrypted form. The data may only be decrypted on the current machine by the current user who executed the command.
## NOTES

## RELATED LINKS

[Connect-ChatSession
Add-ChatPlugin
Save-ChatSessionSettings]()

