//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.Collections.Generic;
using System.Runtime.InteropServices;

using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;
using Modulus.ChatGPS.Utilities;

namespace Modulus.ChatGPS.Services;

public abstract class ChatService : IChatService
{
    public ChatService(AiOptions options, ILoggerFactory? loggerFactory = null, string? userAgent = null)
    {
        this.options = options;
        this.loggerFactory = loggerFactory;
        this.userAgent = userAgent;
    }

    public List<ChatMessage> CreateChat(string prompt)
    {
        var result = new List<ChatMessage>();

        var systemMessage = new ChatMessage(SenderRole.System, prompt);

        result.Add(systemMessage);

        return result;
    }

    public AiOptions ServiceOptions
    {
        get
        {
            return this.options;
        }
    }

    public async Task<IReadOnlyList<ChatMessage>> GetChatCompletionAsync(List<ChatMessage> history, bool? allowAgentAccess)
    {
        ChatMessage nextMessage;

        try
        {
            nextMessage = await GetChatCompletionService().GetNextChatMessageAsync(history, this.options, allowAgentAccess).ConfigureAwait(false);
            this.HasSucceeded = true;
        }
        catch (Exception exception)
        {
            throw new AIServiceException(exception);
        }

        var result = new List<ChatMessage>();

        result.Add(nextMessage);

        return result;
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string,object?>? parameters, bool? allowAgentAccess)
    {
        var kernelFunction = GetKernelWithState().CreateFunctionFromPrompt(definitionPrompt);

        var result = await GetKernelWithState().InvokeFunctionAsync(kernelFunction, this.options, parameters, allowAgentAccess).ConfigureAwait(false);

        this.HasSucceeded = true;

        return result;
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
            PSDecryptor.GetDecryptedStringFromEncryptedUnicodeHexBytes(encryptedString);
    }

    protected bool HasSucceeded { get; private set; }

    private AIChatFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernelWithState();

        AIChatFunction result;

        try
        {
            result = kernel.CreateFunctionFromPrompt(definitionPrompt);
        }
        catch ( Exception exception )
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    protected abstract IAIKernel GetKernel();

    protected virtual Uri? GetDefaultEndpoint()
    {
        return null;
    }

    protected IAIKernel GetKernelWithState()
    {
        var kernel = GetKernel();

        if ( this.pluginTable is null )
        {
            this.pluginTable = new PluginTable();
        }

        kernel.SetPluginTable(this.pluginTable);

        return kernel;
    }

    private IAIKernel GetChatCompletionService()
    {
        return GetKernelWithState();
    }

    protected IAIKernel? serviceKernel;
    protected AiOptions options;
    protected string? userAgent;
    protected PluginTable? pluginTable;

    protected const int tokenLimitDefault = 16384;

    private ILoggerFactory? loggerFactory;
}
