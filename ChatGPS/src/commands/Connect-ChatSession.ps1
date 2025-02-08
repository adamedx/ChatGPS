#
# Copyright (c) Adam Edwards
#
# All rights reserved.

<#
.SYNOPSIS
Creates a new "chat" session between the user and a supported language model. The model may be hosted locally or accessed remotely through a service provider.

.DESCRIPTION
A chat session is a communication channel between the user and an AI language model along with optional associated history of exchanged messages. Commands such as Send-ChatMessage and Invoke-ChatFunction allow users to send messages to the language model using natural language or any other protocol supported by the language model; the language model will return responses as the output of these commands. Before the communication commands may be used, a channel must be created by Create-ChatSession that may then be used by those commands to identify the location of the language model, provide credentials for models that require authentication, and to store the conversation history.

Connect-ChatSession supports both locally hosted models stored in the local device's file system, as well as cloud-hosted models. Typically the former do not require authentication but the latter do. The Provider parameter of the command is used to specify the kind of model, which in turn dictates whether the model is local or remote.

Connect-ChatSession implicitly maintains the concept of a "current" session, i.e. simply by successfully executing the command, this special current session is set and the value of any previously set value for it is overwritten every time Connect-ChatSession is invoked. To override this behavior and execute the command without setting the current session, use the NoSetCurrent parameter; instead of updating the current session, the new session will be returned as output of the command. This allows the creation of multiple sessions without effecting the state of the "default" current session. This is useful when automating interactions between multiple models, or simply using the same model but maintaining separate conversation histories.

By default, the session is created with one of several built-in system prompts that dictate the purpose and style of the conversation. The command also supports providing a custom system prompt instead using the CustomSystemPrompt parameter.

.PARAMETER SystemPromptId
An identifier corresponding to one of the built-in system prompts to be used for the session. Values include PowerShell, General, PowerShellStrict, and Conversational. The default value is PowerShell. The PowerShell prompt focuses on natural language conversations about the PowerShell language and command-line tools and general programming language topics. The General prompt is simply natural language conversation on any topic. The Conversational prompt is similar to General with a focus on making the conversation more interesting. The PowerShellStrict prompt expects natural language instructions for generating PowerShell code and will return only code; the code it returns as output to conversation commands can be directly executed by the PowerShell interpreter.

.PARAMETER CustomSystemPrompt
Allows the user to specify a custom system prompt to steer converation and response output instead of using one of the prompts specified by the SystemPromptId parameter.

.PARAMETER FunctionPrompt
Specify FunctionPrompt so that all chat prompts will be processes through the function specified by FunctionPrompt. The function *must* specify the function using the Handlebars syntax with exactly one parameter named 'input'. See the New-ChatFunction command documentation for more details about function definition syntax.

.PARAMETER Provider
Specifies the language model provider. Currently supported values are LocalOnnx for Onnx (https://onnx.ai/) models hosted on the local file system, or AzureOpenAI for models accessed through the Azure OpenAI Service (https://azure.microsoft.com/en-us/products/ai-services/openai-service). The default value is currently based on the presence of other parameters, though that may change as more providers are added that use the same parameter patterns. To be sure that the correct provider is used, specify this parameter explicitly. Note that LocalOnnx currently requires that this command is invoked on the Windows operating system using the x64 or arm64 processor architectures.

.PARAMETER ApiEndpoint
For remotely hosted models, the API URI that enables access to the model.

.PARAMETER DeploymentName
For remotely hosted models some services may require this as an additional parameter to identify the specific model to use. This parameter usually only applies to remote models.

.PARAMETER ApiKey
Some remotely hosted models that require authentication may support a symmetric key that can be specified through this parameter. WARNING: currently this parameter is specified via plaintext rather than as a securestring. To avoid the value of this key being present in command history, use a command to read it from a secure location such as an Azure KeyVault or a local file with sufficient security measures in place, assign the value of the key to a PowerShell variable, and then use that variable to specify the value of the ApiKey parameter.

.PARAMETER AllowInteractiveSignin
For use with remote models only, specify AllowInteractiveSignin to allow this command or subsequent commands that access the model to invoke a user interface for authentication. This is only applicable when the ApiKey parameter or other non-interactive sign-in mechanisms are not configured for the session. For some model services such as Azure OpenAI this option can be useful if sign-in tools such as the "Az.Accounts" module with its "Login-AzAccount" and "Logout-AzAccount" commands is unavaialble, however it may have some side effects. Because i

.PARAMETER LocalModelPath
For local models such as those supported by the LocalOnnx provider this is the path to the local model in the executing device's file system.

.PARAMETER ModelIdentifier
This parameter may be required for certain providers, particularly for local models.

.PARAMETER TokenLimit
Specifies the maximum number of tokens that should be sent to the model. Tokens are units of semantic meaning similar to the concept of a "word"; messages sent to the model are interpreted as tokens, and models have a limit on the number of tokens that can be processed in a request or returned as a response. The default value of 4096 may be sufficient for most use cases, but some models may support fewer tokens, so the value can be changed so that message commands can attempt to "compress" messages at the expense of losing context / meaning. Alternatively, models that have much higher limits can be fully utilized by setting this value higher so that commands will not prematurely attempt to throw away valuable context.

.PARAMETER TokenStrategy
Specifies the mechanism to use to "compress" messages into fewer tokens (see the TokenLimit parameter for more information on tokens and their impact on conversations and accuracy). By default, the Summarize strategy is used, which will attempt to shorten conversation history by summarizing it and using this smaller summary result to continue conversations once the token limit is reached. The Truncate strategy simply removes a selected set of older messages from the conversation histroy under the assumption that the conversation can be reasonably continued by considering the most recent messages. The None strategy means no attempt will be made to reduce token utilization; this will likely limit the number of exchanges in a conversation, but can allow the user to handle errors that occur when token limits are hit with custom scripting, or can simply be useful in testing or ruling out non-determinism that could be caused by removing conversation context.

.PARAMETER PassThru
By default, Connect-ChatSession returns no output; it simply has the side effect of changing the current session. Specify PassThru to return the value of the session regardless whether the current session is overridden (default behavior) or not (when NoSetCurrent is specified). The resulting output may be used as a parameter to other commands that access models such as Send-ChatMessage, Start-ChatRepl, or Invoke-ChatFunction.

.PARAMETER NoSetCurrent
Specify NoSetCurrent so that the implicit "current" session is not overwritten or otherwise set when this command executes successfully. Instead, a new session independent from any current session will be returned as output of the command. The resulting output may be used as a parameter to other commands that access models such as Send-ChatMessage, Start-ChatRepl, or Invoke-ChatFunction. Thus Connect-ChatSession can be used to create multiple independent chat sessions for different purposes without affecting the current default session.

.PARAMETER NoConnect
By default, this command may attempt to authenticate to the service that hosts the model (for remote models) or access the model's local path (for local models) in order to surface incorrect parameters or access problems before the session is actually used with subsequent commands. To skip this verification, specify the NoConnect parameter. Specifying this may mean that access issues are not discovered until subsequent commands that access the model are executed.

.PARAMETER NoProxy
Specify the NoProxy parameter so ensure that the session will not use an intermediate proxy process to communicate with the model. By default, the session will utilize a proxy that isolates dependencies for the services used to access the language model into a separate process from that of the PowerShell session. This helps avoid incompatibilities with such dependencies and PowerShell itself, and was useful during the early stages of the development of Semantic Kernel which changed frequently. In some cases such as specification of the AllowInteractiveSignin parameter the proxy will not be used due to known user experience issues in that situation. The ForceProxy parameter may be used to force use of the proxy in call cases. At some point the proxy may no longer be required and may eventually be removed. It is possible that code defects in the proxy could introduce errors or other reliability issues, so NoProxy can be specified to remove this risk if problems arise in certain use cases. When the proxy is in use, a log of its activity can be generated if the appropriate values are specified for the LogLevel and LogDirectory parameters.

.PARAMETER ForceProxy
Use ForceProxy to override the command's automatic determination of when to use a proxy process to host language model service dependencies and use the proxy in all cases. This parameter is most likely useful for debugging purposes only and should not be needed.

.PARAMETER LogDirectory
This parameter allows a log to be placed in a certain directory; the log contains information about a local proxy used to isolate the code that interacts with services. If this parameter is not specified, then no long will be written, even if the LogLevel is set to something other than None. If this parameter is specifed, then a file with the name ChatGPSProxy.log will be placed in that directory.

.PARAMETER LogLevel
This parameter only takes effect if LogDirectory is also specified as a valid location for writing a log of proxy operations sent to a local process that interacts with the services that provide the model. By default, the value "Default" currently means there is no logging, which is the same as the value None. A value of Error shows only logs related to errors. The value Debug shows Errors and other common events, and the DebugVerbose shows the highest level of information in the log.

.OUTPUTS
By default, the command has no output. But if the NoSetCurrent or PassThrue parameters are specified, the newly connected session is returned as output and can be used a parameter to other commands.

.EXAMPLE
In this example, a chat session is used to communicate with a model deployment called gpt-4o-mini provided by an Azure OpenAI service resource. This will use the currently signed in credentials from Login-AzAccount by default and will fail if there is no such sign-in or if the signed in user does not have access to the specified model. After the connection is created, the Send-ChatMessage command is used to send a message to the service and receive a response. Note that it is not required to specify the Provider parameter since AzureOpenAI is the default when the ApiEndpint is specified:

PS > Connect-ChatSession -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini # Use Login-AzAccount if this fails.

PS > Send-ChatMessage 'how do I find my mac address?'

Received                 Response
--------                 --------
12/30/2024 9:24:18 PM    ```powershell
                         # This command retrieves the MAC addresses of all network adapters on the system.

                         # Get network adapter information and select the Name and MAC Address properties
                         Get-NetAdapter | Select-Object Name, MacAddress # Displays the Name and MAC Address of each
                         adapter

.EXAMPLE
In this example, a chat session is used to a remote model as in the previous example. In this case, instead of the user's credentials, a symmetric key credential is provided by the ApiKey parameter:

PS > $secretKey = GetMyApiKeyFromSecureLocation
PS > Connect-ChatSession -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini -ApiKey $secretKey
PS > Get-ChatSession

Id                     : 3cb205df-c4e2-4569-a2f3-8a059571ed23
Provider               : AzureOpenAI
IsRemote               : True
ApiEndpoint            : https://myposh-test-2024-12.openai.azure.com/
AllowInteractiveSignin : False
AccessValidated        : False
TokenLimit             : 4096
DeploymentName         : gpt-4o-mini
TotalMessageCount      : 1
CurrentMessageCount    : 1

.EXAMPLE
This example is similar to those above, but it uses the OpenAI provider instead -- since OpenAI does not currently require an ApiEndpoint parameter but does require an ApiKey parameter, use of the OpenAI provider is the default when only ApiKey is specified. For OpenAI however the ModelIdentifier is required:

PS > $secretKey = GetMyApiKeyFromSecureLocation
PS > Connect-ChatSession -ModelIdentifier gpt-4o-mini -ApiKey $secretKey
PS > Get-ChatSession

Id                  : 15934765-10c5-4caf-b477-180abd9d893d
Provider            : OpenAI
IsRemote            : True
AccessValidated     : False
TokenLimit          : 4096
ModelIdentifier     : gpt-4o-mini
TotalMessageCount   : 1
CurrentMessageCount : 1

.EXAMPLE
This example shows how to connect to a local phi-3.5 onnx model -- the Provider parameter may also be omitted in this case because currently when LocalModelPath is specified the LocalOnnx provider is implied (this will likely be impacted by a breaking change when additional local models are supported in the future). The Get-ChatSession command which outputs the current session is used here to show that the values passed to Connect-ChatSesssion are in effect. Lastly, the Start-ChatRepl command is used to start an interactive conversation.

PS > Connect-Chatsession -LocalModelPath '/models/Phi-3.5-mini-instruct-onnx/gpu/gpu-int4-awq-block-128' -ModelIdentifier phi-3.5pu-int4-awq-block-128' -ModelIdentifier phi-3.5
PS > Get-ChatSession

Id                    : f73fcd36-8bf4-42f2-b5b7-6af908b1ac45
Provider              : LocalOnnx
Local Model Path      : /models/Phi-3.5-mini-instruct-onnx/gpu/gpu-int4-awq-block-128
Token Limit           : 4096
Model Identifier      : phi-3.5
Total Message Count   : 1
Current Message Count : 1

PS > Start-ChatRepl

(morpheus) ChatGPS>: hello

Received                 Response
--------                 --------
12/30/2024 11:15:06 PM   Hello! I'm Phi, an AI language model here to assist you with any questions or tasks you have.
                         How can I help you today?

.EXAMPLE
In this example, a session is created as the curent session, and then NoSetCurrent option is used to create two new sessions without impacting the current session. One of the latter two sessions uses the same model as the default which is suitable for professional usage, while the other connects to a personal model for non-work purposes. The Start-ChatRepl command is used with current session, then Send-ChatMessage and Invoke-ChatFunction commands are used with second and third sessions, and finally Start-ChatRepl is used again and it is clear that the messages transmitted with the other sessions did not affect the conversation history of Start-ChatRepl as it still shows the last response from the previous Start-ChatRepl usage on that session as the latest response.

PS > Connect-ChatSession -ApiEndpoint 'https://devteam1-2024-12.openai.azure.com' -DeploymentName gpt-o1 -ApiKey $workKey
PS > $work2 = Connect-ChatSession -NoSetCurrent -ApiEndpoint 'https://devteam1-2024-12.openai.azure.com' -DeploymentName gpt-o1 -ApiKey $workKey
PS > $personal = Connect-ChatSession -NoSetCurrent -ApiEndpoint 'https://myposh-test-2024-12.openai.azure.com' -DeploymentName gpt-4o-mini -ApiKey $personalKey

PS > $unreadMail = GetUnreadMail
PS > $emailSummary = Invoke-ChatFunction SummarizeMail $unreadMail -Session $work2 | Show-Markdown

PS > Start-ChatRepl

(morpheus) ChatGPS>: please translate this Chinese text: '我应该乘坐什么火车去机场？'

Received                 Response
--------                 --------
12/30/2024 11:01:03 AM   The Chinese text '我应该乘坐什么火车去机场？' translates to "Which train should I take to the
                         airport?"

(morpheus) ChatGPS>: .exit

PS > $tahomaWeather = Invoke-WebRequest -UseBasicParsing 'https://forecast.weather.gov/MapClick.php?lat=46.9381&lon=-121.8623&unit=0&lg=english&FcstType=text&TextType=1' | select -ExpandProperty content
PS > Send-ChatMessage -Session $personal "Summarize the plaintext contained in this html content regarding the weather forecast for Mt. Rainier $tahomaWeather"

Received                 Response
--------                 --------
12/30/2024 11:04:22 AM   The weather forecast for the area 7 miles northwest of Mt. Rainier, WA, indicates the
                         following:

                         - **Tonight:** Partly cloudy with a low around 21°F and a light south southwest wind.

                         - **Tuesday:** A 30% chance of snow after 4 PM, partly sunny with a high near 28°F. Wind
                         chill values between 12°F and 22°F, with less than half an inch of new snow expected.

                         - **Tuesday Night:** Snow likely after 10 PM, with a low around 23°F. Wind chill values
                         between 10°F and 15°F, an 80% chance of precipitation, and 1 to 3 inches of new snow
                         accumulation possible.

                         - **New Year's Day (Wednesday):** Snow likely mainly before 4 PM, mostly cloudy, high near
                         29°F, and a 70% chance of precipitation with 1 to 2 inches of new snow expected.

PS > Start-ChatRepl

Received                 Response
--------                 --------
12/30/2024 11:01:03 AM   The Chinese text '我应该乘坐什么火车去机场？' translates to "Which train should I take to the
                         airport?"

(morpheus) ChatGPS>: Thank you!

12/30/2024 11:07:42 AM   You're welcome! If you have any more questions or need help with anything else, feel free to
                         ask!

(morpheus) ChatGPS>:

.LINK
Get-ChatSession
Send-ChatMessage
Invoke-ChatFunction
Start-ChatRepl
#>
function Connect-ChatSession {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [validateset('Default', 'General', 'PowerShell', 'PowerShellStrict', 'Conversational', 'Terse')]
        [string] $SystemPromptId = 'Default',

        [Alias('Prompt')]
        [string] $CustomSystemPrompt,

        [string] $FunctionPrompt,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [validateset('AzureOpenAI', 'OpenAI', 'LocalOnnx')]
        [string] $Provider,

        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true)]
        [Uri] $ApiEndpoint,

        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true)]
        [string] $DeploymentName,

        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true)]
        [string] $ApiKey,

        [parameter(parametersetname='remoteaiservice')]
        [switch] $AllowInteractiveSignin,

        [parameter(parametersetname='localmodel', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [string] $LocalModelPath,

        [parameter(parametersetname='localmodel', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [parameter(parametersetname='remoteaiservice', valuefrompipelinebypropertyname=$true)]
        [string] $ModelIdentifier,

        [parameter(valuefrompipelinebypropertyname=$true)]
        [int32] $TokenLimit = 4096,

        [validateset('None', 'Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Summarize',

        [switch] $PassThru,

        [switch] $NoSetCurrent,

        [switch] $NoConnect,

        [switch] $NoProxy,

        [switch] $ForceProxy,

        [string] $LogDirectory = $null,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel = 'Default'
    )

    $options = [Modulus.ChatGPS.Models.AiOptions]::new()

    $options.ApiEndpoint = $ApiEndpoint
    $options.DeploymentName = $DeploymentName
    $options.ModelIdentifier = $ModelIdentifier
    $options.ApiKey = $ApiKey
    $options.TokenLimit = $TokenLimit
    $options.LocalModelPath = $LocalModelPath
    $options.SigninInteractionAllowed = $AllowInteractiveSignin.IsPresent

    $isLocal = !  ( ! $options.LocalModelPath )

    if ( $Provider ) {
        $options.Provider = $Provider
    } else {
        if ( ! $isLocal ) {
            $options.Provider = if ( $options.ApiEndpoint ) {
                'AzureOpenAI'
            } else {
                'OpenAI'
            }
        } else {
            $options.Provider = 'LocalOnnx'
        }
    }

    if ( $isLocal ) {
        if ( ! $NoConnect.IsPresent -and ! ( test-path $options.LocalModelPath ) ) {
            throw [System.IO.FileNotFoundException]::new(
                "The path $($options.LocalModelPath) specified for a local model could not be found. " +
                "Specify a valid model path in the local file system and retry the operation.")
        }
    }

    # There is some confusion over deploymentName and modelId, so for now
    # we will say that local models should not have only a modelId, we will
    # explicitly ignore DeploymentName
    if ( $isLocal ) {
        if ( $DeploymentName ) {
            write-warning "A local model was specified -- the DeploymentName parameter will be ignored"
            $options.DeploymentName = ''
        }
    }

    $functionInfo = if ( $FunctionPrompt ) {
        if ( ! $FunctionPrompt.Contains('{{$input}}') ) {
            throw [ArgumentException]::new("Function prompts must have exactly one argument specified and it must be named 'input'. Specify the prompt with the 'input' parameter included with handlebar syntax, e.g. '{{`$input}}'")
        }

        @{
            Parameters = @('input')
            Definition = $FunctionPrompt
        }
    }

    $systemPrompt = if ( $CustomSystemPrompt ) {
        $CustomSystemPrompt
    } else {
        $targetSystemPromptId = if ( $SystemPromptId -eq 'Default' ) {
            if ( $FunctionPrompt ) {
                'Terse'
            } else {
                'General'
            }
        } else {
            $SystemPromptId
        }

        # Don't override existing function info
        if ( ! $functionInfo ) {
            $functionInfo = ([PromptBook]::GetFunctionInfo($targetSystemPromptId))
        }

        [PromptBook]::GetDefaultPrompt($targetSystemPromptId)
    }

    $functionDefinition = $null
    $functionParameters = $null

    if ( $functionInfo ) {
        $functionParameters = [string[]] $functionInfo.Parameters
        $functionDefinition = [string] $functionInfo.Definition

        if ( $functionInfo.Parameters.Count -ne 1 -or ! $functionInfo.Parameters.Contains('input') ) {
            throw [ArgumentException]::new("Function prompts must have exactly one argument specified and it must be named 'input'. Specify the prompt with the 'input' parameter included with handlebar syntax, e.g. '{{$input}}'")
        }
    }

    if ( $ForceProxy.IsPresent -and $NoProxy.IsPresent ) {
        throw [ArgumentException]::new("The ForceProxy and NoProxy parameters may not both be specified -- specify exactly one of them or neither.")
    }

    # Proxy mode is not currently compatible with interactive signin for remote models
    $proxyIncompatibility = ! $isLocal -and ! $ApiKey -and $AllowInteractiveSignin.IsPresent
    $proxyDisallowed = $proxyIncompatibility -and ! $ForceProxy.IsPresent
    $useProxy = ! $NoProxy.IsPresent -and ! $proxyDisallowed

    if ( ! $useProxy ) {
        if ( $proxyDisallowed -and ! $NoProxy.IsPresent) {
            write-verbose "No ApiKey specified for a remote model, and AllowInteractiveSignin is specified, so proxy will not be used to prevent signin problems. Use Login-AzAccount and Logout-AzAccount to sign in with the correct identity if access fails."
        }
    } elseif ( $proxyIncompatibility ) {
        write-warning "AllowInteractiveSignin was specified for a remote model that requires authentication and proxy mode was forced with ForceProxy. You may be asked to re-authenticate frequently."
    }

    $targetProxyPath = if ( $useProxy ) {
        write-verbose "Model will be accessed using a proxy"
        "$psscriptroot/../../lib/AIProxy.exe"
    } else {
        write-verbose "Model will be accessed without a proxy"
    }

    if ( $targetProxyPath ) {
        write-debug "Accessing the model using proxy mode using proxy application at '$targetProxyPath'"
    }

    $session = CreateSession $options -Prompt $systemPrompt -AiProxyHostPath $targetProxyPath -FunctionPrompt $functionDefinition -FunctionParameters $functionParameters -SetCurrent:(!$NoSetCurrent.IsPresent) -NoConnect:($NoConnect.IsPresent) -TokenStrategy $TokenStrategy -LogDirectory $LogDirectory -LogLevel $LogLevel

    if ( ! $isLocal -and ! $NoConnect.IsPresent ) {
        try {
            $session.SendStandaloneMessage('Are you there?') | out-null
        } catch {
            $exceptionMessage = if ( $_.Exception.InnerException ) {
                $_.Exception.InnerException.Message
            } else {
                $_.Exception.Message
            }

            $apiEndpointAdvice = if ( $ApiEndpoint ) {
                "Ensure that the remote API URI '$($ApiEndpoint)' is accessible from this device."
            } else {
                "Ensure that you have network connectivity to the remote service hosting the model."
            }

            $signinAdvice = if ( $ApiKey ) {
                'Also ensure that the specified API key is valid for the given model API URI.'
            } else {
                'Also ensure that you have signed in using a valid identity that has been granted access to the given model API URI. ' +
                '(e.g. for Azure OpenAI models try signing out with Logout-AzAccount, then retry the command, or explicitly use' +
                'LoginAzAccount to sign in as the correct identity). You can also specify the AllowInteractiveSignin parameter with ' +
                'with this command and retry if you do not have access to signin tools for the remote model; this may result in ' +
                'multiple requests to re-authenticate.'
            }
            throw [ApplicationException]::new("Attempt to establish a test connection to the remote model failed.`n" +
                                              "$($apiEndpointAdvice)`n" +
                                              "$($signinAdvice)`nSpecify the NoConnect option to skip this test when invoking this command.`n" +
                                              "$($exceptionMessage)", $_.Exception)
        }
    }

    if ( $PassThru.IsPresent -or $NoSetCurrent.IsPresent ) {
        $session
    }
}
