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

    public string GenerateMessage(string prompt)
    {
        return GenerateMessageInternal(prompt, false);
    }

    public string GenerateFunctionResponse(string prompt)
    {
        return GenerateMessageInternal(prompt, true);
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

    private string GenerateMessageInternal(string prompt, bool isFunction)
    {
        var newMessageRole = AuthorRole.User;

        this.conversationBuilder.AddMessageToConversation(this.totalChatHistory, newMessageRole, prompt);
        ConversationBuilder.CopyMessageToConversation(this.chatHistory, this.totalChatHistory, this.totalChatHistory.Count - 1);

        string? response = null;

        Microsoft.SemanticKernel.Diagnostics.HttpOperationException? tokenException = null;
        Exception? lastException = null;

        Task<string>? messageTask = null;

        for ( int attempt = 0; attempt < 3; attempt++ )
        {
            try
            {
                tokenException = null;
                lastException = null;

                if ( isFunction )
                {
                    messageTask = this.conversationBuilder.InvokeFunctionAsync(this.chatHistory);
                }
                else
                {
                    messageTask = this.conversationBuilder.SendMessageAsync(this.chatHistory);
                }

                messageTask.Wait();

                response = messageTask.Result;
                break;
            }
            catch (Exception e)
            {
                lastException = e;

                var messageException = (
                    ( messageTask is not null ) &&
                    ( messageTask.Status == System.Threading.Tasks.TaskStatus.Faulted ) &&
                    ( messageTask.Exception is not null ) ) ?
                    messageTask.Exception.InnerException as Microsoft.SemanticKernel.Diagnostics.HttpOperationException : null;

                if ( messageException is not null && IsTokenLimitException( messageException ) )
                {
                    tokenException = messageException;
                    var reducedHistory = this.tokenReducer.Reduce(this.chatHistory, newMessageRole);

                    if ( reducedHistory != null )
                    {
                        this.chatHistory = reducedHistory;
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        if ( tokenException != null || response == null )
        {
            this.conversationBuilder.AddMessageToConversation(this.chatHistory, AuthorRole.Assistant, "My apologies, I was unable to respond to your last message.");
        }

        UpdateHistoryWithResponse();

        if ( tokenException != null )
        {
            throw tokenException;
        }
        else if ( lastException is not null )
        {
            throw lastException;
        }
        else if ( response == null )
        {
            throw new ArgumentException("The AI assistant was unable to generate a response.");
        }

        return response;
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

