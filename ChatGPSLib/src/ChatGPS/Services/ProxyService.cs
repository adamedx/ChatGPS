//
// Copyright 2023, Adam Edwards
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
    public ProxyService(ServiceBuilder.ServiceId serviceId, AiOptions options, string proxyHostPath, int idleTimeoutMs = 0, string? logFilePath = null, bool whatIfMode = false)
    {
        Channel.SetDefaultProxyPath(proxyHostPath);

        this.proxyTransport = new Transport();
        this.serviceId = serviceId;
        this.proxyConnection = new ProxyConnection(serviceId, options, idleTimeoutMs);
        this.whatIfMode = whatIfMode;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return new ChatHistory(prompt);
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history)
    {
        ConnectAiService();

        var sendChatRequest = new SendChatRequest(history);

        var request = ProxyRequest.FromRequestCommand(sendChatRequest);

        var response = await this.proxyTransport.SendAsync(this.proxyConnection, request);

        var sendChatResponse = (SendChatResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(SendChatResponse));

        if ( sendChatResponse is null )
        {
            throw new ProxyException("A null reference was returned for the chat request by the AI service.");
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

    private void ConnectAiService()
    {
        if ( ! this.proxyConnection.IsConnectedToAiService )
        {
            var createConnectionRequest = new CreateConnectionRequest();
            createConnectionRequest.ServiceId = this.serviceId;
            createConnectionRequest.ConnectionOptions = this.proxyConnection.ServiceOptions;

            var request = ProxyRequest.FromRequestCommand(createConnectionRequest);

            var task = proxyTransport.SendAsync(this.proxyConnection, request);

            var response = task.Result;

            var createConnectionResponse = (CreateConnectionResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(CreateConnectionResponse));

            if ( createConnectionResponse is null )
            {
                throw new ProxyException("Unable to create a connection to the service proxy because the proxy response was empty or otherwise invalid");
            }

            if ( response.Status != ProxyResponse.ResponseStatus.Success )
            {
                Exception? innerException = ( response.Exceptions != null && response.Exceptions.Length > 0 ) ? response.Exceptions[0] : null;

                throw new ProxyException("The request to establish a connection to a service proxy failed.", new ProxyException(innerException));
            }

            this.proxyConnection.BindTargetService(createConnectionResponse.ConnectionId);
        }
    }

    Transport proxyTransport;
    ServiceBuilder.ServiceId serviceId;
    bool whatIfMode;

    ProxyConnection proxyConnection;

}
