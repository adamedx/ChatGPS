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
using Microsoft.SemanticKernel.ChatCompletion;

internal class ConversationBuilder
{
    internal ConversationBuilder(IChatService chatService, string? chatFunctionPrompt = null)
    {
        this.chatFunctionPrompt = chatFunctionPrompt;
        this.chatService = chatService;
    }

    internal ChatHistory CreateConversationHistory(string systemPrompt)
    {
        return this.chatService.CreateChat(systemPrompt);
    }

    internal async Task<string> SendMessageAsync(ChatHistory chatHistory)
    {
        var responses = await this.chatService.GetChatCompletionAsync(chatHistory);

        string results = "";

        foreach ( var response in responses )
        {
            if ( response is not null && response.Content is not null )
            {
                results += response.Content;
                UpdateHistoryWithResponse(chatHistory, response.Content);
            }
        }

        return results;
    }

    internal async Task<string> InvokeFunctionAsync(ChatHistory chatHistory, string? prompt = null)
    {
        InitializeSemanticFunction();

        if ( this.chatFunction == null )
        {
            throw new ArgumentException("Unable to generate a function response -- this chat session does not have an optional associated chat function");
        }

        var targetPrompt = prompt is not null ? prompt : chatHistory[chatHistory.Count - 1].Content;

        if ( prompt is not null )
        {
            AddMessageToConversation(chatHistory, AuthorRole.User, prompt);
        }

        var response = await this.chatService.GetKernel().InvokeAsync(this.chatFunction);

        var resultString = response.GetValue<string>();

        var targetResult = resultString is not null ? resultString : "I was unable to respond to your message.";

        UpdateHistoryWithResponse(chatHistory, targetResult);

        return targetResult;
    }

    internal void AddMessageToConversation(ChatHistory chatHistory, AuthorRole role, string prompt, IReadOnlyDictionary<string,object?>? messageProperties = null)
    {
        var targetProperties = messageProperties is not null ? messageProperties : CreateMessageProperties();
        chatHistory.AddMessage(role, prompt, null, targetProperties);
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

        var  content = sourceHistory[messageIndex].Content;

        if ( content is null )
        {
            throw new ArgumentException("Unexpected null content in message");
        }

        destinationHistory.AddMessage(sourceHistory[messageIndex].Role, content, null, sourceHistory[messageIndex].Metadata);
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

    private ReadOnlyDictionary<string,object?>? CreateMessageProperties()
    {
        var dictionary = new Dictionary<string,object?>
        {
            { "Timestamp", JsonSerializer.Serialize<DateTimeOffset>(DateTimeOffset.Now) },
            { "MessageIndex", JsonSerializer.Serialize<int>(this.messageIndex++) }
        };

        return new ReadOnlyDictionary<string,object?>(dictionary);
    }

    private IChatService chatService;

    private int messageIndex = 0;

    private string? chatFunctionPrompt;
    private KernelFunction? chatFunction;

}
