//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Services;

internal class Connection
{
    internal Connection(Guid Id, IChatService chatService)
    {
        this.Id = Id;
        this.ChatService = chatService;
        this.ChatCompletion = this.ChatService.GetChatCompletion();
    }

    internal Guid Id { get; private set; }

    internal IChatService ChatService { get; private set; }
    internal IChatCompletionService ChatCompletion {get; private set; }
}
