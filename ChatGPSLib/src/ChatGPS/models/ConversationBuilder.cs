//
// Copyright (c) Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Orchestration;
using Microsoft.SemanticKernel.AI.ChatCompletion;

internal class ConversationBuilder
{
    internal ConversationBuilder(IChatService chatService, string? chatFunctionPrompt = null)
    {
        this.chatFunctionPrompt = chatFunctionPrompt;
        this.chatService = chatService;
        this.completionService = chatService.GetChatCompletion();

        if ( this.completionService == null )
        {
            throw new ArgumentException("Specified chat service did not provide a chat completion interface.");
        }
    }

    internal ChatHistory CreateConversationHistory(string systemPrompt)
    {
        return this.chatService.CreateChat(systemPrompt);
    }

    internal async Task<string> SendMessageAsync(ChatHistory chatHistory)
    {
        string response = await this.completionService.GenerateMessageAsync(chatHistory);

        UpdateHistoryWithResponse(chatHistory, response);

        return response;
    }

    internal async Task<string> InvokeFunctionAsync(ChatHistory chatHistory, string prompt)
    {
        InitializeSemanticFunction();

        if ( this.chatFunction == null )
        {
            throw new ArgumentException("Unable to generate a function response -- this chat session does not have an optional associated chat function");
        }

        AddMessageToConversation(chatHistory, AuthorRole.User, prompt);

        var response = await this.chatFunction.InvokeAsync(prompt, this.chatService.GetKernel());

        var resultString = response.GetValue<string>();

        var targetResult = resultString is not null ? resultString : "I was unable to respond to your message.";

        UpdateHistoryWithResponse(chatHistory, targetResult);

        return targetResult;
    }

    internal void AddMessageToConversation(ChatHistory chatHistory, AuthorRole role, string prompt, IDictionary<string,string>? messageProperties = null)
    {
        var targetProperties = messageProperties is not null ? messageProperties : CreateMessageProperties();
        chatHistory.AddMessage(role, prompt, targetProperties);
    }

    static internal void CopyMessageToConversation(ChatHistory destinationHistory, ChatHistory sourceHistory, int messageIndex)
    {
        if ( sourceHistory[messageIndex].Role == destinationHistory[destinationHistory.Count - 1].Role )
        {
            var targetRole = destinationHistory[destinationHistory.Count - 1].Role;
            var targetMessage = destinationHistory[destinationHistory.Count - 1].Content;
            var sourceMessage = sourceHistory[messageIndex].Content;

            throw new ArgumentException(String.Format("Mismatch in destination {0}. Target = {1}, Source = {2}", targetRole, targetMessage, sourceMessage));
        }

        destinationHistory.AddMessage(sourceHistory[messageIndex].Role, sourceHistory[messageIndex].Content, sourceHistory[messageIndex].AdditionalProperties);
    }

    internal void UpdateHistoryWithResponse(ChatHistory chatHistory, string response)
    {
        AddMessageToConversation(chatHistory, AuthorRole.Assistant, response);
    }

    private void InitializeSemanticFunction()
    {
        if ( ( this.chatFunctionPrompt != null ) &&
             ( this.chatFunction == null ) )
        {
            this.chatFunction = this.chatService.CreateFunction(this.chatFunctionPrompt);
        }
    }

    private Dictionary<string,string> CreateMessageProperties()
    {
        return new Dictionary<string,string>
        {
            { "Timestamp", JsonSerializer.Serialize<DateTimeOffset>(DateTimeOffset.Now) },
            { "MessageIndex", JsonSerializer.Serialize<int>(this.messageIndex++) }
        };
    }

    private IChatService chatService;
    private IChatCompletion completionService;

    private int messageIndex = 0;

    private string? chatFunctionPrompt;
    private ISKFunction? chatFunction;

}
