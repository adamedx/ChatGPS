//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.AI.ChatCompletion;

public class ChatSession
{
    public ChatSession(IChatService chatService, string systemPrompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, object? tokenReductionParameters = null, string? chatFunctionPrompt = null)
    {
        this.chatFunctionPrompt = chatFunctionPrompt;
        this.conversationBuilder = new ConversationBuilder(chatService, chatFunctionPrompt);

        this.chatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);
        this.totalChatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);

        this.tokenReducer = new TokenReducer(conversationBuilder, tokenStrategy, tokenReductionParameters);
    }

    public async Task<string> GenerateMessageAsync(string prompt)
    {
        var newMessageRole = AuthorRole.User;

        this.conversationBuilder.AddMessageToConversation(this.totalChatHistory, newMessageRole, prompt);
        ConversationBuilder.CopyMessageToConversation(this.chatHistory, this.totalChatHistory, this.totalChatHistory.Count - 1);

        string? response = null;

        for ( int attempt = 0; attempt < 3; attempt++ )
        {
            try
            {
                response = await this.conversationBuilder.SendMessageAsync(this.chatHistory);
                break;
            }
            catch (Microsoft.SemanticKernel.Diagnostics.HttpOperationException e)
            {
                if ( IsTokenLimitException(e) )
                {
                    var reducedHistory = this.tokenReducer.Reduce(this.chatHistory, newMessageRole);

                    if ( reducedHistory != null )
                    {
                        this.chatHistory = reducedHistory;
                    }
                }
                else
                {
                    throw;
                }
            }
        }

        if ( response is null )
        {
            throw new NotSupportedException("The AI service was not able to return a response");
        }

        UpdateHistoryWithResponse();

        return response;
    }

    public async Task<string> GenerateFunctionResponse(string prompt)
    {
        this.conversationBuilder.AddMessageToConversation(this.totalChatHistory, AuthorRole.User, prompt);
        ConversationBuilder.CopyMessageToConversation(this.chatHistory, this.totalChatHistory, this.totalChatHistory.Count - 1);

        return await conversationBuilder.InvokeFunctionAsync(this.chatHistory, prompt);
    }

    public ChatHistory History
    {
        get
        {
            return this.totalChatHistory;
        }
    }

    public ChatHistory CurrentHistory
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

    public ReadOnlyCollection<double> ExceededTokenLimitSizeList
     {
         get
         {
             return new ReadOnlyCollection<double>(this.tokenReducer.PastLimitTokenSize);
         }
     }

    public ReadOnlyCollection<double> ReducedTokenSizeList
     {
         get
         {
             return new ReadOnlyCollection<double>(this.tokenReducer.ReducedTokenSize);
         }
     }

    private bool IsTokenLimitException( Microsoft.SemanticKernel.Diagnostics.HttpOperationException operationException )
    {
        var tokenLimitExceeded = false;

        if ( operationException.ResponseContent is not null )
        {
            var responseContent = operationException.ResponseContent;

            JsonNode? jsonNode = null;

            try
            {
                jsonNode = JsonNode.Parse(responseContent);
            }
            catch
            {
            }

            string? responseCode = null;

            if ( ( jsonNode != null ) && jsonNode["error"]!["code"]!.AsValue().TryGetValue<string>( out responseCode ) )
            {
                if ( responseCode == "context_length_exceeded" )
                {
                    tokenLimitExceeded = true;
                }
            }
        }

        return tokenLimitExceeded;
    }


    private void UpdateHistoryWithResponse()
    {
        ConversationBuilder.CopyMessageToConversation(this.totalChatHistory, this.chatHistory, this.chatHistory.Count - 1);
    }

    private ConversationBuilder conversationBuilder;
    private ChatHistory chatHistory;
    private ChatHistory totalChatHistory;
    private string? chatFunctionPrompt;
    private TokenReducer tokenReducer;
}

