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
    public static ChatSession CreateSession(AiOptions options, string prompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, string? chatFunctionPrompt = null, IChatService? chatService = null)
    {
        var targetChatService = chatService;

        if ( targetChatService == null ) {
            targetChatService = new OpenAIChatService(options);
        }

        string? targetChatFunctionPrompt = string.IsNullOrEmpty(chatFunctionPrompt) ? null : chatFunctionPrompt;

        return new ChatSession(targetChatService, prompt, tokenStrategy, targetChatFunctionPrompt);
    }
}
