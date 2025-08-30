Model Provider Authentication
=============================


#### Remote model authentication

Note that for externally hosted models such as those from Azure OpenAI a credential is required. Unless the `NoConnect` option is specified, the `Connect-ChatSession` command
will attempt to access and therefore authenticate to a remote model using the configured credentials; the command will fail if access is not allowed.  When `NoConnect` is specified,
the access and authentication attempt will be deferred until the first use of subsequent commands like `Send-ChatMessage`.

The mechanism for configuring credentials used to access the model will vary based on the model service provider.

##### Authentication with Azure OpenAI

Azure OpenAI supports multiple mechanisms for specifying credentials:

  * Symmetric key: For Azure OpenAI models the `ApiKey` parameter of `Connect-ChatSession` may be used to specify a secret key used to access the Azure OpenAI service instance hosting the model.
  * Entra ID authentication: Alternatively if the `ApiKey` parameter is not specified for Azure OpenAI models, the command will try to use a credential for a currently signed-in Entra ID
    identity such as an Entra ID user account sign-in. Such sign-ins can be accomplished using tools such as the `Login-AzAccount` command from the `Az.Accounts` PowerShell module.
    * The `AllowInteractiveSignin` parameter will trigger an Entra ID user sign-in and is useful if the `Az.Accounts` module and `Login-AzAccount` commands are unavailable. However, this sign-in flow
      still requires interaction even if the user is already signed in. To avoid the superfluous interactions, use `Login-AzAccount` when possible.

##### Non-interactive remote model authentication

Use of a symmetric key parameter like `ApiKey` for remotely hosted models such as Azure OpenAI and OpenAI require careful handling of the key. Such keys are highly sensitive secrets
and because of this, it may be safer to to specify the `ApiKey` parameter to the command indirectly so that the secret is not present in command history. Options include:

* Reading the credential from a file stored in a secure location and assigning the file content to a variable, then specifying that variable as the `ApiKey`
  parameter for the `Connect-ChatSession` command
* Reading all parameters for `Connect-ChatSession` from a file stored securely, and piping it into the `Connect-ChatSession` command which accepts all required
  parameters as input from the pipeline. In general you can choose to specify some parameters via the pipeline, and some via the command line.

The latter approach of reading the session parameters from a file and sending them through the pipeline is illustrated with the two examples below for Azure OpenAI and OpenAI:

**Azure OpenAI:**

```powershell
# Create this file just once
$securelocation = '<your-secure-folder>'
$configfolder = mkdir "$securelocation/chatgpsconfig"
$configpath = "$configfolder/azureopenai.config"

'
{
  "Provider": "AzureOpenAI",
  "ApiEndpoint": "<your-azureopenai-resource-uri>",
  "DeploymentName": "<yourmodelname>",
  "ApiKey": "<your-azureopenai-key>"
}
' | Set-Content $configpath


# Create a session using this file below at any time in the future --
# saves typing and keeps sensitive secrets out of command history
Get-Content <your-config-path> | ConvertFrom-Json | Connect-ChatSession
```

**OpenAI:**

```powershell
# Create this file just once
$securelocation = '<your-secure-folder>'
$configfolder = mkdir "$securelocation/chatgpsconfig"
$configpath = "$configfolder/openai.config"

'
{
  "Provider": "OpenAI",
  "ModelIdentifier": "gpt-4o-mini",
  "ApiKey": "<your-openai-key>"
}
' | Set-Content $configpath


# Create a session using this file below at any time in the future
Get-Content <your-config-path> | ConvertFrom-Json | Connect-ChatSession
```

**Google:**

```powershell
Connect-ChatSession -Provider Google -ModelIdentifier gemini-2.0-flash-001 -ReadApiKey
```
