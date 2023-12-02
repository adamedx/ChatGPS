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
    public static ChatSession CreateSession(AiOptions options, string prompt, IChatService? chatService = null)
    {
        var targetChatService = chatService;

        if ( targetChatService == null ) {
            ChatGPS.chatService = ChatGPS.chatService != null ? ChatGPS.chatService : new OpenAIChatService(options);
            targetChatService = ChatGPS.chatService;
        }

        var history = targetChatService.CreateChat(prompt);

        return new ChatSession(history);
    }

    private static IChatService? chatService;
}
