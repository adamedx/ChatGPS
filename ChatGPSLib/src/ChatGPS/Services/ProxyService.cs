//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

internal class ProxyService : IChatService
{
    public ProxyService(ServiceBuilder.ServiceId serviceId)
    {
        this.serviceId = serviceId;
    }

    public ChatHistory CreateChat(string prompt)
    {
        throw new NotImplementedException("Not implemented");
    }

    public Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history)
    {
        throw new NotImplementedException("Not implemented");
    }

    public KernelFunction CreateFunction(string definitionPrompt)
    {
        throw new NotImplementedException("Not implemented");
    }
    public Kernel GetKernel()
    {
        throw new NotImplementedException("Not implemented");
    }

    ServiceBuilder.ServiceId serviceId;
}
