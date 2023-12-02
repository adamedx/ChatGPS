//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel.AI.ChatCompletion;

public class ChatSession
{
    public ChatSession(ChatHistory chatHistory)
    {
        this.chatHistory = chatHistory;
    }

#pragma warning disable CS1998
    public async Task<string> GenerateMessageAsync(string prompt)
#pragma warning restore CS1998
    {
        return prompt;
    }

    public ChatHistory History
    {
        get
        {
            return this.chatHistory;
        }
    }

    private ChatHistory chatHistory;
}

