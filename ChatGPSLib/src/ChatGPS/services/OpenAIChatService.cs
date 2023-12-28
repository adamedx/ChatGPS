//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.AI.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.AI.OpenAI;

using Modulus.ChatGPS.Models;

internal class OpenAIChatService : IChatService
{
    internal OpenAIChatService(AiOptions options)
    {
        this.options = options;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return this.GetChatCompletion().CreateNewChat(prompt);
    }

    public ISKFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernel();

        var requestSettings = new OpenAIRequestSettings();

        return kernel.CreateSemanticFunction(definitionPrompt, requestSettings: requestSettings);
    }

    public IChatCompletion GetChatCompletion()
    {
        var kernel = GetKernel();

        return kernel.GetService<IChatCompletion>();
    }

    public IKernel GetKernel()
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

        var builder = new KernelBuilder();

        builder.WithAzureOpenAIChatCompletionService(
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

    private IKernel? serviceKernel;
    private AiOptions options;
}
