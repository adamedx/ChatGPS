//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.AI.ChatCompletion;

using Modulus.ChatGPS.Models;

internal class OpenAIChatService : IChatService
{
    internal OpenAIChatService(AiOptions options)
    {
        this.options = options;
    }

    public ChatHistory CreateChat(string prompt)
    {
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


        var kernel = builder.Build();

        var chatGPT = kernel.GetService<IChatCompletion>();

        return chatGPT.CreateNewChat(prompt);
    }

    private AiOptions options;
}
