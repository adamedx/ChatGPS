//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

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

    public KernelFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernel();

        var requestSettings = new OpenAIPromptExecutionSettings();

        return kernel.CreateFunctionFromPrompt(definitionPrompt, executionSettings: requestSettings);
    }

    public IChatCompletionService GetChatCompletion()
    {
        var kernel = GetKernel();

        var chatCompletionService = kernel.GetAllServices<IChatCompletionService>().FirstOrDefault();

        if ( chatCompletionService is null )
        {
            throw new InvalidOperationException("A null result was obtained for the chat completion service");
        }

        return chatCompletionService;
    }

    public Kernel GetKernel()
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

    private Kernel? serviceKernel;
    private AiOptions options;
}
