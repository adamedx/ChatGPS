Model Provider Authentication
=============================

The `Connect-ChatSession` command establishes a connection to a specific model, and for remote APIs, that will almost certainly require authentiation. Because the specification of models, remote endpoint locations, and credentials is non-uniform across models, you'll need to familiarize yourself with the specific `Connect-ChatSession` parameters to specify for a given model.

## Authentication at session creation

Note that for externally hosted models such as those from Azure OpenAI a credential is required. Unless the `NoConnect` option is specified, the `Connect-ChatSession` command
will attempt to access and therefore authenticate to a remote model using the configured credentials; the command will fail if access is not allowed.  When `NoConnect` is specified,
the access and authentication attempt will be deferred until the first use of subsequent commands like `Send-ChatMessage`.

The mechanism for configuring credentials used to access the model will vary based on the model service provider.

## OAuth2 authentication with Azure OpenAI

Azure OpenAI supports the use of both Entra ID for authentication as well as a symmetric key. For Entra ID, ChatGPS relies on the `Login-AzAccount` command from the [Az.Accounts](https://powershellgallery.com/packages/Az.Accounts) module to sign you in; once you've authenticated, you can use `Connect-ChatSession` to create a session that uses the credentials from that authentication:

**Entra ID:**

```powershell
# You only need to do Login-AzAccount once. The credential usually persists even across
# reboots unless you sign out.
Login-AzAccount
Connect-ChatSession -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini
```

It should be noted that this Entra ID approach works on all platforms supported by ChatGPS including Windows, MacOS, and Linux.

## Key-based credentials

Almost all providers, including Azure OpenAI, allow the use of a symmetric key credential to authenticate. For such providers, you can specify that key to `Connect-ChatSession` through the `ReadApiKey` parameter as follows:

**Azure OpenAI:**

```powershell
Connect-ChatSession -Provider AzureOpenAI -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ReadApiKey
```

The `ReadApiKey` parameter allows you to securely enter the key so that it is not present in your terminal's command history and is also encrypted in memory. Use of the `ReadApiKey` parameter is equivalent to using the command `Get-ChatEncryptedUnicodeKeyCredential` command to read the key, and then specifying that value to `Connect-ChatSession` explicitly:

```powershell
$encryptedKey = Get-ChatEncryptedUnicodeKeyCredential
Connect-ChatSession -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ApiKey $encryptedKey
```

Currently the `ReadApiKey` parameter and `Get-ChatEncryptedUnicodeKeyCredential` command are only supported on the Windows operating system. For other operating systems such as Linux and MacOS, you will need to specify a plain text key which you can configure through environment variables, possibly sourced by a script that reads the plan text key from a secure location. Use the `ApiKey` parameter to specify the plain text key along with the `PlainTextApiKey` parameter in such cases.

### Using stored keys

Use of `ReadApiKey` strengthens protection of the key from leakage or unauthorized access, but the manual acquisition of the key for each session creation is inconvenient and presents its own risks (e.g. the probably use of "cut and paste" of the plaintext key via the clipboard). As an alternative, you can store your model's key a secure location and encrypt it:

* Use a solution such as [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/basic-concepts) or equivalent cloud provider secret management features to store the key. You can use a script to obtain the key from the resource using your credentials and pass it programatically in encrypted form to `Connect-ChatSession`.
* You can use a similar approach to store it in an encrypted form in the local file system.
* You can use the `Save-ChatSessionSetting` command to save the session as a setting; when doing so, it encrypts the key and stores it in the settings file at `~/.chatgps/settings.json`.

The use of Azure Key Vault is given here as an example:

```powershell
$encryptedApiKey = Get-AzKeyVaultSecret -VaultName AIVault -Name AzureOpenAIApiKey -AsPlainText | Get-ChatEncryptedUnicodeKeyCredential
Connect-ChatSession -Provider AzureOpenAI -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ApiKey $encryptedApiKey
```

That same example will need a change on non-Windows platforms since `Get-ChatEncryptedUnicodeKeyCredential` is not available:

```
$unencryptedApiKey = Get-AzKeyVaultSecret -VaultName AIVault -Name AzureOpenAIApiKey -AsPlainText
Connect-ChatSession -Provider AzureOpenAI -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ApiKey $unencryptedApiKey -PlainTextApiKey
```

#### Saving the key into a file

On the Windows platform, you can encrypt the key and then save it into a file using `Get-ChatEncryptedUnicodeKeyCredential`:

```powershell
Get-ChatEncryptedUnicodeKeyCredential | out-file ~/mysecuredirectory/gemini2key-encrypted.txt
```

You can inspect the resulting file to confirm that it does not contain the plaintext key. Now you can simply read that file to obtain the key and use it with the `ApiKey` parameter of `Connect-ChatSession` to create the session:

```powershell
$encryptedKey = Get-Content ~/mysecuredirectory/gemini2key-encrypted.txt
Connect-ChatSession -Provider Google -ModelIdentifier gemini-2.0-flash-001 -ApiKey $encryptedKey
```

On non-Windows platforms, ChatGPS itself does not provide a way to encrypt the key, so you'll need to decide on a solution for encrypting the key and otherwise securing it. You can then use that solution's commands for reading and decrypting it to pass it to the `ApiKey` parameter of `Connect-ChatSession` along with the `PlainTextApiKey` parameter.

#### Saving the key in ChatGPS settings

ChatGPS provides a settings file that stores session configuration so that you don't have to invoke `Connect-ChatSession` each time you start a new PowerShell session where you need to use ChatGPS. Once you've created a session with `Connect-ChatSession`, you can save it using the `Save-ChatSessionSetting` command; this saves all the parameters you specified to `Connect-ChatSession`, including API keys:

```powershell
Save-ChatSessionSetting -Name MySetting # if the session was given a name in `Connect-ChatSession` with the Name parameter

# OR

Save-ChatSessionSetting -Current -SaveAs MyNewSetting # if the setting had no name
```

On the Windows platform, the keys will be encrypted by default; you can inspect the file at `~/.chatgps/settings.json` to confirm that the plaintext key is not present in the settings file content.

# Provider authentication examples

The set of providers supported by ChatGPS require specific parameters for authenticating and connecting with `Connect-ChatSession`, though these variations do have categories of similarity. See the examples below of `Connect-ChatSession` usage for each provider:

**OpenAI:**

```powershell
Connect-ChatSession Provider OpenAI -ModelIdentifier gpt-4o-mini -ReadApiKey
```

**Google:**

```powershell
Connect-ChatSession -Provider Google -ModelIdentifier gemini-2.0-flash-001 -ReadApiKey
```

**Azure OpenAI:**

```powershell
# Using Entra ID
Connect-ChatSession -Provider AzureOpenAI -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini # Use Login-AzAccount first

# OR

# Use an API key
Connect-ChatSession -Provider AzureOpenAI -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ReadApiKey
```

**Anthropic:**

```powershell
Connect-ChatSession -Provider Anthropic -ModelIdentifier claude-sonnet-4-20250514 -ReadApiKey
```


