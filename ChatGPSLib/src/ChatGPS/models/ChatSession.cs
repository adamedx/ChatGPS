//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Services;
using Modulus.ChatGPS.Plugins;

public class ChatSession
{
    public ChatSession(IChatService chatService, string systemPrompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, object? tokenReductionParameters = null, int latestContextLimit = -1, object? customContext = null, string? name = null)
    {
        chatService.ServiceOptions.Validate();

        this.Id = Guid.NewGuid();

        this.conversationBuilder = new ConversationBuilder(chatService);

        this.chatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);
        this.totalChatHistory = conversationBuilder.CreateConversationHistory(systemPrompt);

        this.publicChatHistory = new ChatMessageHistory(this.chatHistory);
        this.publicTotalChatHistory = new ChatMessageHistory(this.totalChatHistory);

        this.tokenReducer = new TokenReducer(conversationBuilder, tokenStrategy, tokenReductionParameters);

        this.chatService = chatService;

        this.AiOptions = new AiProviderOptions(chatService.ServiceOptions);
        this.AccessValidated = false;

        this.LastResponseError = null;

        this.latestContextLimit = latestContextLimit;

        this.CustomContext = customContext;

        this.Name = name;
    }

    public string SendStandaloneMessage(string prompt, bool? allowAgentAccess = null)
    {
        ConversationBuilder temporaryConversation = new ConversationBuilder(this.chatService);

        var history = conversationBuilder.CreateConversationHistory(prompt);

        Task<string> messageTask;

        try
        {
            messageTask = temporaryConversation.SendMessageAsync(history, allowAgentAccess);
            messageTask.Wait();
        }
        catch (Exception e)
        {
            UpdateStateWithLatestResponse(e, true);
            throw;
        }

        UpdateStateWithLatestResponse(null, true);

        return messageTask.Result;
    }

    public string GenerateMessage(string prompt)
    {
        return GenerateMessageInternal(prompt);
    }

    public string GenerateFunctionResponse(string functionDefinition, string prompt)
    {
        return GenerateMessageInternal(prompt, functionDefinition);
    }

    public Function CreateFunction(string name, string[] parameters, string definition, bool replace = false)
    {
        var function = new Function(name, parameters, definition);

        FunctionTable.GlobalFunctions.AddFunction(function, replace);

        return function;
    }

    public async Task<string> InvokeFunctionAsync(Guid functionId, Dictionary<string,object?>? boundParameters = null)
    {
        var function = FunctionTable.GlobalFunctions.GetFunctionById(functionId);

        return await function.InvokeFunctionAsync(this.chatService, boundParameters);
    }

    public void UpdateLastResponse(string updatedResponse)
    {
        if ( this.History[this.History.Count - 1].Role != ChatMessage.SenderRole.Assistant )
        {
            throw new InvalidOperationException("There is no last response from the assistant to update");
        }

        var lastMessage = this.History[this.History.Count - 1];

        this.History.RemoveAt(this.History.Count - 1);
        this.CurrentHistory.RemoveAt(this.CurrentHistory.Count - 1);

        var updatedMessage = new ChatMessage(new ChatMessageContent(lastMessage.SourceChatMessageContent.Role, updatedResponse, lastMessage.SourceChatMessageContent.ModelId, lastMessage.SourceChatMessageContent.InnerContent, lastMessage.SourceChatMessageContent.Encoding, lastMessage.SourceChatMessageContent.Metadata));

        this.History.Add(updatedMessage);
        this.CurrentHistory.Add(updatedMessage);
    }

    public void AddPlugin(string name, object[]? parameters = null)
    {
        this.chatService.AddPlugin(name, parameters);
    }

    public void RemovePlugin(string name)
    {
        this.chatService.RemovePlugin(name);
    }

    public ChatMessageHistory History
    {
        get
        {
            return this.publicTotalChatHistory;
        }
    }

    public ChatMessageHistory CurrentHistory
    {
        get
        {
            return this.publicChatHistory;
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

    public AiProviderOptions AiOptions { get; private set; }

    public bool AccessValidated { get; private set; }

    public bool IsRemote
    {
        get
        {
            return ( this.AiOptions.LocalModelPath?.Length ?? 0 ) == 0;
        }
    }

    public bool AllowInteractiveSignin
    {
        get
        {
            return this.AiOptions?.SigninInteractionAllowed ?? false;
        }
    }

    public int HistoryContextLimit
    {
        get
        {
            return this.latestContextLimit;
        }
    }

    public Exception? LastResponseError { get; private set; }

    public object? CustomContext { get; private set; }

    public string? Name { get; private set; }

    public IEnumerable<PluginInfo> Plugins
    {
        get
        {
            return this.chatService.Plugins;
        }
    }

    private string GenerateMessageInternal(string prompt, string? functionDefinition = null)
    {
        var newMessageRole = AuthorRole.User;

        this.conversationBuilder.AddMessageToConversation(this.totalChatHistory, newMessageRole, prompt, new TimeSpan(0));
        ConversationBuilder.CopyMessageToConversation(this.chatHistory, this.totalChatHistory, this.totalChatHistory.Count - 1);

        string? response = null;

        AIServiceException? tokenException = null;

        Exception? lastException = null;

        Task<string>? messageTask = null;

        for ( int attempt = 0; attempt < 4; attempt++ )
        {
            // Assumption: network error handling (e.g. throttling retries) is addressed
            // by the service client layer itself. This layer only contains error handling
            // specific to the application, e.g. token limit management.

            try
            {
                tokenException = null;
                lastException = null;

                if ( functionDefinition is not null )
                {
                    var chatFunction = new Function(new string[] {"input"}, functionDefinition);

                    messageTask = this.conversationBuilder.InvokeFunctionAsync(this.chatHistory, chatFunction, prompt);
                }
                else
                {
                    UpdateHistoryContextFromLimit();

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
                }
            }
        }

        if ( tokenException != null || response == null )
        {
            this.conversationBuilder.AddMessageToConversation(this.chatHistory, AuthorRole.Assistant, "My apologies, I was unable to respond to your last message.");
        }

        var responseException = tokenException ?? lastException;

        // So I had to write this strange code that invokes a method in two different blocks, one that throws
        // and one that doesn't, because the compiler's nullable comes up with a false positive.
        // It seems to give me false positives if I try to assign to a nullable exception variable and then
        // throw if it's non-null and return the response, which it thinks can somehow be null -- it can't!
        // If the compiler wants me to write something terrible to make it happy, so be it.
        //
        // Note that this wasn't a problem until I invoked a method before the last throw -- it doesn't matter
        // that that method correctly handles null apparently.
        if ( response == null )
        {
            var genericException = new ArgumentException("The AI assistant was unable to generate a response.");
            UpdateStateWithLatestResponse(genericException);
            throw genericException;
        }

        UpdateStateWithLatestResponse(responseException);

        if ( responseException is not null )
        {
            throw responseException;
        }

        return response;
    }

    private void UpdateHistoryContextFromLimit()
    {
        if ( this.latestContextLimit != -1 )
        {
            ChatHistory? targetHistory = null;

            if ( this.chatHistory.Count > 1 && ( this.chatHistory.Count % 2 ) == 0 )
            {
                var systemMessage = this.chatHistory[0];

                // This conversion to empty string is a way to make nullable
                // avoid false positives :(
                string systemPrompt = systemMessage.Content ?? "";

                if ( systemPrompt.Length > 0 )
                {
                    var newHistory = this.conversationBuilder.CreateConversationHistory(systemPrompt);

                    // Copy the latest limit * 2 messages
                    var earliestIndex = Math.Max(1, ( this.chatHistory.Count - 1 ) - this.latestContextLimit * 2);

                    for ( int currentIndex = earliestIndex; currentIndex < this.chatHistory.Count; currentIndex++ )
                    {
                        var currentMessage = this.chatHistory[currentIndex];
                        string currentPrompt = currentMessage.Content ?? ""; // More nullable protection

                        if ( currentPrompt.Length > 0 )
                        {
                            this.conversationBuilder.AddMessageToConversation(newHistory, currentMessage.Role, currentPrompt);
                        }
                        else
                        {
                            break;
                        }
                    }

                    targetHistory = newHistory;
                }

                if ( targetHistory is null )
                {
                    throw new ArgumentException("The conversation history is invalid.");
                }
            }

            if ( targetHistory is null )
            {
                throw new ArgumentException("The conversation history is invalid.");
            }

            this.chatHistory = targetHistory;
        }
    }

    private void UpdateStateWithLatestResponse(Exception? responseException = null, bool noHistory = false)
    {
        this.LastResponseError = responseException;

        if ( responseException is null )
        {
            this.AccessValidated = true;

            if ( ! noHistory )
            {
                ConversationBuilder.CopyMessageToConversation(this.totalChatHistory, this.chatHistory, this.chatHistory.Count - 1);
            }
        }
    }

    private ConversationBuilder conversationBuilder;
    private ChatHistory chatHistory;
    private ChatHistory totalChatHistory;
    private ChatMessageHistory publicChatHistory;
    private ChatMessageHistory publicTotalChatHistory;
    private TokenReducer tokenReducer;
    private IChatService chatService;
    private int latestContextLimit;
}

