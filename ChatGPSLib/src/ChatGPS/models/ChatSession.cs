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
using Microsoft.SemanticKernel.ChatCompletion;

public class ChatSession
{
    public ChatSession(IChatService chatService, string systemPrompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, object? tokenReductionParameters = null, string? chatFunctionPrompt = null, string[]? chatFunctionParameters = null)
    {
        this.Id = new Guid();

        this.chatFunctionPrompt = chatFunctionPrompt;
        this.chatFunction = chatFunctionPrompt is not null ? new Function(chatFunctionParameters, chatFunctionPrompt) : null;
        this.conversationBuilder = new ConversationBuilder(chatService, chatFunctionPrompt);

        this.chatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);
        this.totalChatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);

        this.tokenReducer = new TokenReducer(conversationBuilder, tokenStrategy, tokenReductionParameters);

        this.SessionFunctions = new FunctionTable();

        this.AIService = chatService;
    }

    public string GenerateMessage(string prompt)
    {
        return GenerateMessageInternal(prompt, false);
    }

    public string GenerateFunctionResponse(string prompt)
    {
        return GenerateMessageInternal(prompt, true);
    }

    public Function CreateFunction(string name, string[] parameters, string definition, bool replace = false)
    {
        var function = new Function(name, parameters, definition);

        this.SessionFunctions.AddFunction(function, replace);

        return function;
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

    public Guid Id { get; private set; }

    public FunctionTable SessionFunctions { get; private set; }

    public IChatService AIService {get; private set; }

    private string GenerateMessageInternal(string prompt, bool isFunction)
    {
        var newMessageRole = AuthorRole.User;

        this.conversationBuilder.AddMessageToConversation(this.totalChatHistory, newMessageRole, prompt);
        ConversationBuilder.CopyMessageToConversation(this.chatHistory, this.totalChatHistory, this.totalChatHistory.Count - 1);

        string? response = null;

        AIServiceException? tokenException = null;

        Exception? lastException = null;

        Task<string>? messageTask = null;

        int retryWaitMs = 0;
        int nextRetryWaitMs = 0;

        for ( int attempt = 0; attempt < 4; attempt++ )
        {
            // There is a retry here to handle throttling from the service; currently
            // the retry timeout value returned by the service is not accessible through the SDK,
            // so we implement a form of exponential backoff after the first retry.
            if ( retryWaitMs > 0 )
            {
                System.Threading.Thread.Sleep(retryWaitMs);
                retryWaitMs = 0;
                nextRetryWaitMs = Math.Min(nextRetryWaitMs * 2, 120000);
            }

            try
            {
                tokenException = null;
                lastException = null;

                if ( isFunction )
                {
                    if ( this.chatFunction is null )
                    {
                        throw new ArgumentException("Attempt to invoke a function when the session does not contain one");
                    }

                    messageTask = this.conversationBuilder.InvokeFunctionAsync(this.chatHistory, this.chatFunction);
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
                    messageTask.Exception.InnerException as AIServiceException : null;

                if ( messageException is not null )
                {
                    if ( messageException.ExceededTokenLimit )
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
                    else if ( messageException.ThrottleRetryMsHint > 0 )
                    {
                        if ( nextRetryWaitMs == 0 )
                        {
                            // We use the retry value from the exception only on the first try since it is
                            // merely a hint due to limitations the current SDK. Subsequent retries will
                            // layer a backoff strategy on top of this first timeout.
                            nextRetryWaitMs = messageException.ThrottleRetryMsHint;
                        }

                        retryWaitMs = nextRetryWaitMs;
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

    private void UpdateHistoryWithResponse()
    {
        ConversationBuilder.CopyMessageToConversation(this.totalChatHistory, this.chatHistory, this.chatHistory.Count - 1);
    }

    private ConversationBuilder conversationBuilder;
    private ChatHistory chatHistory;
    private ChatHistory totalChatHistory;
    private string? chatFunctionPrompt;
    private Function? chatFunction;
    private TokenReducer tokenReducer;
}

