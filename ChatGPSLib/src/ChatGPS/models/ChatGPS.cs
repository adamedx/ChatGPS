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
    public static ChatSession CreateSession(AiOptions options, string prompt, string? chatFunctionPrompt, IChatService? chatService = null)
    {
        var targetChatService = chatService;

        if ( targetChatService == null ) {
            targetChatService = new OpenAIChatService(options);
        }

        string? targetChatFunctionPrompt = string.IsNullOrEmpty(chatFunctionPrompt) ? null : chatFunctionPrompt;

        return new ChatSession(targetChatService, prompt, targetChatFunctionPrompt);
    }
}
