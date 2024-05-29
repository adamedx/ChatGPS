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
using Modulus.ChatGPS.Models.Proxy;


internal class ProxyService : IChatService
{
    public ProxyService(ServiceBuilder.ServiceId serviceId, AiOptions options, string proxyHostPath, string? logFilePath = null, int idleTimeoutMs = 0, bool whatIfMode = false)
    {
        Channel.SetDefaultLogFilePath(logFilePath);
        Channel.SetDefaultProxyPath(proxyHostPath);

        this.proxyTransport = new Transport();
        this.serviceId = serviceId;
        this.proxyConnection = new ProxyConnection(this.proxyTransport, serviceId, options, idleTimeoutMs);
        this.whatIfMode = whatIfMode;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return new ChatHistory(prompt);
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history)
    {
        var sendChatRequest = new SendChatRequest(history);

        var request = ProxyRequest.FromRequestCommand(sendChatRequest);

        var response = await this.proxyTransport.SendAsync(this.proxyConnection, request);

        var sendChatResponse = (SendChatResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(SendChatResponse));

        if ( sendChatResponse is null )
        {
            throw new AIServiceException("A null reference was returned for the chat request by the AI service.", null);
        }

        var resultList = new List<ChatMessageContent>();

        if ( sendChatResponse.ChatResponse is not null )
        {
            resultList.Add(sendChatResponse.ChatResponse);
        }

        return new ReadOnlyCollection<ChatMessageContent>(resultList);
    }

    public KernelFunction CreateFunction(string definitionPrompt)
    {
        throw new NotImplementedException("Not implemented");
    }

    public Kernel GetKernel()
    {
        throw new NotImplementedException("Not implemented");
    }

    Transport proxyTransport;
    ServiceBuilder.ServiceId serviceId;
    bool whatIfMode;

    ProxyConnection proxyConnection;

}
