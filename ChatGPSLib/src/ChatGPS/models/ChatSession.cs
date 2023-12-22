//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Orchestration;
using Microsoft.SemanticKernel.AI.ChatCompletion;

public class ChatSession
{
    public ChatSession(IChatService chatService, string systemPrompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, object? tokenReductionParameters = null, string? chatFunctionPrompt = null)
    {
        this.chatService = chatService;
        this.tokenReducer = new TokenReducer(chatService, tokenStrategy, tokenReductionParameters);
        this.chatHistory = chatService.CreateChat(systemPrompt);
        this.totalChatHistory = chatService.CreateChat(systemPrompt);
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
        this.totalChatHistory.AddMessage(AuthorRole.User, prompt);

        string? response = null;

        for ( int attempt = 0; attempt < 2; attempt++ )
        {
            try
            {
                response = await completionService.GenerateMessageAsync(this.chatHistory);
                break;
            }
            catch (Exception e)
            {
                if ( ( attempt == 0 ) && IsTokenLimitException(e) )
                {
                    var reducedHistory = this.tokenReducer.Reduce(this.chatHistory);

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
            return this.totalChatHistory;
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
             return this.tokenReducer.PastLimitTokenSize;
         }
     }

    public ReadOnlyCollection<double> ReducedTokenSizeList
     {
         get
         {
             return this.tokenReducer.ReducedTokenSize;
         }
     }

    private bool IsTokenLimitException( Exception e )
    {
        var operationException = e as Microsoft.SemanticKernel.Diagnostics.HttpOperationException;

        var tokenLimitExceeded = false;

        if ( operationException is not null && operationException.ResponseContent is not null )
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


    private void UpdateHistoryWithResponse(string response)
    {
        this.totalChatHistory.AddMessage(AuthorRole.Assistant, response);
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
    private ChatHistory totalChatHistory;
    private string? chatFunctionPrompt;
    private ISKFunction? chatFunction;
    private TokenReducer tokenReducer;
}

