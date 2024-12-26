//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public abstract class ChatService : IChatService
{
    public ChatService(AiOptions options)
    {
        this.options = options;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return new ChatHistory(prompt);
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history)
    {
        IReadOnlyList<ChatMessageContent> result;

        try
        {
            result = await GetChatCompletionService().GetChatMessageContentsAsync(history);
        }
        catch (Exception exception)
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string,object?>? parameters)
    {
        var kernelFunction = GetKernel().CreateFunctionFromPrompt(definitionPrompt);

        var kernelArguments = new KernelArguments(parameters ?? new Dictionary<string,object?>());

        var result = await GetKernel().InvokeAsync(kernelFunction, kernelArguments);

        return new FunctionOutput(result);
    }

    private KernelFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernel();

        var requestSettings = new OpenAIPromptExecutionSettings();

        KernelFunction result;

        try
        {
            result = kernel.CreateFunctionFromPrompt(definitionPrompt, executionSettings: requestSettings);
        }
        catch ( Exception exception )
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    protected abstract Kernel GetKernel();

    private IChatCompletionService GetChatCompletionService()
    {
        if ( this.chatCompletionService is null )
        {
            Kernel kernel;

            try
            {
                kernel = GetKernel();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }

            try
            {
                this.chatCompletionService = kernel.GetAllServices<IChatCompletionService>().FirstOrDefault();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }
        }

        if ( this.chatCompletionService is null )
        {
            throw new InvalidOperationException("A null result was obtained for the chat completion service");
        }

        return this.chatCompletionService;
    }

    protected Kernel? serviceKernel;
    protected IChatCompletionService? chatCompletionService;
    protected AiOptions options;
}
