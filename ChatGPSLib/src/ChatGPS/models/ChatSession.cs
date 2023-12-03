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
    public ChatSession(IChatCompletion completionService, ChatHistory chatHistory)
    {
        this.completionService = completionService;
        this.chatHistory = chatHistory;
    }

    public async Task<string> GenerateMessageAsync(string prompt)
    {
        this.chatHistory.AddMessage(AuthorRole.User, prompt);
        var response = await completionService.GenerateMessageAsync(this.chatHistory);

        UpdateHistoryWithResponse(response);

        return response;
    }

    public ChatHistory History
    {
        get
        {
            return this.chatHistory;
        }
    }

    private void UpdateHistoryWithResponse(string response)
    {
        this.chatHistory.AddMessage(AuthorRole.Assistant, response);
    }

    private IChatCompletion completionService;
    private ChatHistory chatHistory;
}

