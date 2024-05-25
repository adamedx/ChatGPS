//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS;

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

public class ChatGPS
{
    public static ChatSession CreateSession(AiOptions options, string? aiProxyHostPath, string prompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, string? chatFunctionPrompt = null, IChatService? chatService = null)
    {
        var targetChatService = chatService;

        if ( targetChatService == null )
        {
            targetChatService =
                aiProxyHostPath is not null ?
                new ProxyService(ServiceBuilder.ServiceId.AzureOpenAi, options, aiProxyHostPath) :
                new OpenAIChatService(options);
        }

        string? targetChatFunctionPrompt = string.IsNullOrEmpty(chatFunctionPrompt) ? null : chatFunctionPrompt;

        return new ChatSession(targetChatService, prompt, tokenStrategy, null, targetChatFunctionPrompt);
    }
}
