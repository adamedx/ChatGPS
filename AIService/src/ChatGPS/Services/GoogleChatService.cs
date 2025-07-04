//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.Google;
using Microsoft.Extensions.DependencyInjection;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class GoogleChatService : ChatService
{
    internal GoogleChatService(AiOptions options, string? userAgent = null) : base(options, userAgent) { }

    protected override Kernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier is null )
        {
            throw new ArgumentException("A deployment name for the language model must be specified.");
        }

        if ( this.options.ApiKey is null )
        {
            throw new ArgumentException("An API key is required for the language model service.");
        }

        var builder = Kernel.CreateBuilder();

        var cleartextKey = GetCompatibleApiKey(this.options.ApiKey, this.options.PlainTextApiKey);

#pragma warning disable SKEXP0070

        builder.AddGoogleAIGeminiChatCompletion(
            modelId : this.options.ModelIdentifier,
            serviceId : this.options.ServiceIdentifier,
            apiKey: cleartextKey);

#pragma warning restore SKEXP0070

        // Configure throttling retry behavior
        builder.Services.ConfigureHttpClientDefaults(c =>
        {
            c.AddStandardResilienceHandler(o =>
            {
                o.Retry.ShouldRetryAfterHeader = true;
                o.Retry.ShouldHandle = args => ValueTask.FromResult(args.Outcome.Result?.StatusCode is System.Net.HttpStatusCode.TooManyRequests);
            });
        });

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
    }
}
