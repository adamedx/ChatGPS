//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Orchestration;
using Microsoft.SemanticKernel.AI.ChatCompletion;

public class ChatSession
{
    public ChatSession(IChatService chatService, string systemPrompt, string? chatFunctionPrompt)
    {
        this.chatService = chatService;
        this.chatHistory = chatService.CreateChat(systemPrompt);
        this.completionService = chatService.GetChatCompletion();
        this.chatFunctionPrompt = chatFunctionPrompt;

        if ( this.completionService == null )
        {
            throw new ArgumentException("Specified chat service did not provide a chat completion interface.");
        }
    }

    public async Task<string> GenerateMessageAsync(string prompt)
    {
        this.chatHistory.AddMessage(AuthorRole.User, prompt);
        var response = await completionService.GenerateMessageAsync(this.chatHistory);

        UpdateHistoryWithResponse(response);

        return response;
    }

    public async Task<string> GenerateFunctionResponse(string prompt)
    {
        InitializeSemanticFunction();

        if ( this.chatFunction == null )
        {
            throw new ArgumentException("Unable to generate a function response -- this chat session does not have an optional associated chat function");
        }

        this.chatHistory.AddMessage(AuthorRole.User, prompt);
        var response = await this.chatFunction.InvokeAsync(prompt, this.chatService.GetKernel());

        var resultString = response.GetValue<string>();

        var targetResponse = "I was unable to respond to your message.";

        if ( resultString != null )
        {
            targetResponse = resultString;
        }

        UpdateHistoryWithResponse(targetResponse);

        return resultString == null ? "" : resultString;
    }

    public ChatHistory History
    {
        get
        {
            return this.chatHistory;
        }
    }

    public bool HasFunction
    {
        get
        {
            return this.chatFunctionPrompt != null;
        }
    }

    private void UpdateHistoryWithResponse(string response)
    {
        this.chatHistory.AddMessage(AuthorRole.Assistant, response);
    }

    private void InitializeSemanticFunction()
    {
        if ( ( this.chatFunctionPrompt != null ) &&
             ( this.chatFunction == null ) )
        {
            this.chatFunction = this.chatService.CreateFunction(this.chatFunctionPrompt);
        }
    }

    private IChatService chatService;
    private IChatCompletion completionService;
    private ChatHistory chatHistory;
    private string? chatFunctionPrompt;
    private ISKFunction? chatFunction;
}

