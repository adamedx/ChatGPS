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

public class OpenAIChatService : IChatService
{
    public OpenAIChatService(AiOptions options)
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

    private Kernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ApiEndpoint == null )
        {
            throw new ArgumentException("An API endpoint must be specified.");
        }

        if ( this.options.ModelIdentifier == null )
        {
            throw new ArgumentException("An identifier for the language model must be specified.");
        }

        if ( this.options.ApiKey == null )
        {
            throw new ArgumentException("An API key for the AI service must be specified.");
        }

        var builder = Kernel.CreateBuilder();

        builder.AddAzureOpenAIChatCompletion(
            this.options.ModelIdentifier,
            this.options.ApiEndpoint.ToString(),
            this.options.ApiKey);

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
    }

    private IChatCompletionService GetChatCompletionService()
    {
        if ( this.chatCompletionService is null )
        {
            var kernel = GetKernel();

            this.chatCompletionService = kernel.GetAllServices<IChatCompletionService>().FirstOrDefault();
        }

        if ( this.chatCompletionService is null )
        {
            throw new InvalidOperationException("A null result was obtained for the chat completion service");
        }

        return this.chatCompletionService;
    }

    private Kernel? serviceKernel;
    private IChatCompletionService? chatCompletionService;
    private AiOptions options;
}
