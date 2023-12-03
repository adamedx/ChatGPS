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
            targetChatService = new OpenAIChatService(options);
        }

        var history = targetChatService.CreateChat(prompt);

        if ( targetChatService.ChatCompletion == null )
        {
            throw new ArgumentException("Specified chat service did not provide a chat completion interface.");
        }

        return new ChatSession(targetChatService.ChatCompletion, history);
    }
}
