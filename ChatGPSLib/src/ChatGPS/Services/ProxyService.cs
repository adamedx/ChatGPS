//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using System.Collections.Generic;
using System.Collections.ObjectModel;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Proxy;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;
using Modulus.ChatGPS.Models.Proxy;


internal class ProxyService : IChatService
{
    public ProxyService(AiOptions options, string proxyHostPath, string? logFilePath = null, string? logLevel = null, int idleTimeoutMs = 60000, bool whatIfMode = false)
    {
        this.proxyTransport = new Transport();
        this.proxyConnection = new ProxyConnection(this.proxyTransport, options, proxyHostPath, logFilePath, logLevel, idleTimeoutMs);
        this.whatIfMode = whatIfMode;
        this.pluginTable = new PluginTable();

        // Must explicitly init within this constructor itself, a method
        // invoked from the constructor is not enough to avoid a superfluous CS8618
        // See https://github.com/dotnet/roslyn/issues/32358
        this.serviceOptions = new AiOptions(options);

        this.initialized = false;
    }

    public void Initialize()
    {
        this.ServiceOptions.Validate();

        this.proxyConnection.Initialize();

        UpdateServiceOptions(this.proxyConnection.ServiceOptions);

        if ( this.initialized )
        {
            throw new InvalidOperationException("The object may not be re-initialized");
        }

        this.initialized = true;
    }

    public ChatHistory CreateChat(string prompt)
    {
        // No CheckInitialized since this is a purely local operation
        return new ChatHistory(prompt);
    }

    public AiOptions ServiceOptions
    {
        get
        {
            return this.serviceOptions;
        }
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history, bool? allowAgentAccess)
    {
        CheckInitialized();

        var sendChatRequest = new SendChatRequest(history, this.pluginTable.Plugins, allowAgentAccess);

        var request = ProxyRequest.FromRequestCommand(sendChatRequest);

        var response = await this.proxyTransport.SendAsync(this.proxyConnection, request);

        var sendChatResponse = (SendChatResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(SendChatResponse));

        if ( sendChatResponse is null )
        {
            throw new AIServiceException("A null reference was returned for the chat request by the AI service.");
        }

        var resultList = new List<ChatMessageContent>();

        if ( sendChatResponse.ChatResponse is not null )
        {
            resultList.Add(sendChatResponse.ChatResponse);
        }

        return new ReadOnlyCollection<ChatMessageContent>(resultList);
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string,object?>? parameters, bool? allowAgentAccess)
    {
        CheckInitialized();

        var invokeFunctionRequest = new InvokeFunctionRequest(definitionPrompt, this.pluginTable.Plugins, parameters ?? new Dictionary<string,object?>(), allowAgentAccess);

        var request = ProxyRequest.FromRequestCommand(invokeFunctionRequest);

        var response = await this.proxyTransport.SendAsync(this.proxyConnection, request);

        var invokeFunctionResponse = (InvokeFunctionResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(InvokeFunctionResponse));

        if ( invokeFunctionResponse is null )
        {
            throw new AIServiceException("A null reference was returned for the function request by the AI service.");
        }

        if ( invokeFunctionResponse.Output is null )
        {
            throw new AIServiceException("The proxy returned a response for a function invocation but its result was a null reference");
        }

        return invokeFunctionResponse.Output;
    }

    public IPluginTable Plugins
    {
        get
        {
            CheckInitialized();

            return this.pluginTable;
        }
    }

    private void UpdateServiceOptions(AiOptions serviceOptions)
    {
        // This constructor strips out any sensitive fields
        this.serviceOptions = new AiOptions(serviceOptions);
    }

    private void CheckInitialized()
    {
        if ( ! this.initialized )
        {
            throw new InvalidOperationException("The object has not been initialized");
        }
    }

    Transport proxyTransport;

    bool whatIfMode;

    AiOptions serviceOptions;

    ProxyConnection proxyConnection;
    PluginTable pluginTable;

    bool initialized;
}
