//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Plugins.Core;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Services;

public abstract class ChatService : IChatService
{
    public ChatService(AiOptions options, string? userAgent = null)
    {
        this.options = options;
        this.userAgent = userAgent;
        this.initialized = false;
    }

    public void Initialize()
    {
        if ( this.initialized )
        {
            throw new InvalidOperationException("The object may not be re-initialized");
        }

        GetKernel();

        this.initialized = true;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return new ChatHistory(prompt);
    }

    public AiOptions ServiceOptions
    {
        get
        {
            return this.options;
        }
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history, bool? allowAgentAccess)
    {
        IReadOnlyList<ChatMessageContent> result;

        var requestSettings = new OpenAIPromptExecutionSettings();

        var allowFunctionCall = ( allowAgentAccess is not null ) ? (bool) allowAgentAccess :
            ( this.options.AllowAgentAccess is not null ? (bool) this.options.AllowAgentAccess : false );

        if ( allowFunctionCall )
        {
            requestSettings.FunctionChoiceBehavior = FunctionChoiceBehavior.Auto();
        }

        try
        {
            result = await GetChatCompletionService().GetChatMessageContentsAsync(history, requestSettings, GetKernelWithState()).ConfigureAwait(false);
            this.HasSucceeded = true;
        }
        catch (Exception exception)
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string,object?>? parameters, bool? allowAgentAccess)
    {
        var requestSettings = new PromptExecutionSettings();

        var allowFunctionCall = ( allowAgentAccess is not null ) ? (bool) allowAgentAccess :
            ( this.options.AllowAgentAccess is not null ? (bool) this.options.AllowAgentAccess : false );

        if ( allowFunctionCall )
        {
            requestSettings.FunctionChoiceBehavior = FunctionChoiceBehavior.Auto();
        }

        var executionSettings = new Dictionary<string,PromptExecutionSettings>
        {
            { PromptExecutionSettings.DefaultServiceId, requestSettings }
        };

        var kernelFunction = GetKernelWithState().CreateFunctionFromPrompt(definitionPrompt);

        var kernelArguments = new KernelArguments(parameters ?? new Dictionary<string,object?>(), executionSettings);

        var result = await GetKernelWithState().InvokeAsync(kernelFunction, kernelArguments).ConfigureAwait(false);

        this.HasSucceeded = true;

        return new FunctionOutput(result);
    }

    public IPluginTable Plugins
    {
        get
        {
            GetKernelWithState();

            if ( this.pluginTable is null )
            {
                throw new InvalidOperationException("The plugin table was not initialized");
            }

            return this.pluginTable;
        }
    }

    protected string GetCompatibleApiKey(string encryptedString, bool? isUnencrypted)
    {
        // Encryption is only supported on Windows -- assume the string is already decrypted
        // when not on Windows or if the isUnencrypted flag is true.
        return ! OperatingSystem.IsWindows() || ( isUnencrypted ?? false ) ?
            encryptedString :
            GetDecryptedStringFromEncryptedUnicodeHexBytes(encryptedString);
    }

    protected string GetDecryptedStringFromEncryptedUnicodeHexBytes(string encryptedString)
    {
        // Ensure that on non-Windows platforms we do not execute this method by throwing an
        // exception. This also avoids compiler warning CA1416.
        if ( ! OperatingSystem.IsWindows() )
        {
            throw new PlatformNotSupportedException("Encryption support is not available for this platform; it is only available for the Windows platform.");
        }

        if ( ( encryptedString.Length % 2 ) != 0 )
        {
            throw new ArgumentException("The specified string format is invalid -- it must contain an even number of characters, all of which must be hexadecimal digits");
        }

        var encryptedBytes = new byte[encryptedString.Length / 2];
        var currentByteCharacters = new char[2];
        int destination = 0;

        for ( var source = 0; source < encryptedString.Length; source += 2 )
        {
            currentByteCharacters[0] = encryptedString[source];
            currentByteCharacters[1] = encryptedString[source + 1];
            encryptedBytes[destination++] = Convert.ToByte(new string(currentByteCharacters), 16);
        }

        var decryptedBytes = ProtectedData.Unprotect(encryptedBytes, null, DataProtectionScope.CurrentUser);

        // This MUST be unicode -- apparently the serialized output uses unicode
        var result = System.Text.Encoding.Unicode.GetString(decryptedBytes);

        return result;
    }

    protected bool HasSucceeded { get; private set; }

    private KernelFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernelWithState();

        var requestSettings = new OpenAIPromptExecutionSettings();

        KernelFunction result;

        try
        {
            result = kernel.CreateFunctionFromPrompt(definitionPrompt, executionSettings: requestSettings);
        }
        catch ( Exception exception )
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    protected abstract Kernel GetKernel();

    protected Kernel GetKernelWithState()
    {
        CheckInitialized();

        var kernel = GetKernel();

        if ( this.pluginTable is null )
        {
            this.pluginTable = new PluginTable(kernel);
        }

        return kernel;
    }

    protected void CheckInitialized()
    {
        if ( ! this.initialized )
        {
            throw new InvalidOperationException("The object has not been initialized");
        }
    }

    private IChatCompletionService GetChatCompletionService()
    {
        if ( this.chatCompletionService is null )
        {
            Kernel kernel;

            try
            {
                kernel = GetKernelWithState();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }

            try
            {
                this.chatCompletionService = kernel.GetAllServices<IChatCompletionService>().FirstOrDefault();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }
        }

        if ( this.chatCompletionService is null )
        {
            throw new InvalidOperationException("A null result was obtained for the chat completion service");
        }

        return this.chatCompletionService;
    }

    protected Kernel? serviceKernel;
    protected IChatCompletionService? chatCompletionService;
    protected AiOptions options;
    protected string? userAgent;
    protected PluginTable? pluginTable;
    protected bool initialized;
}
