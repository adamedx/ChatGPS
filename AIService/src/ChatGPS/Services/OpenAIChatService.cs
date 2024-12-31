//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.Extensions.DependencyInjection;
using Azure.AI.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class OpenAIChatService : ChatService
{
    internal OpenAIChatService(AiOptions options) : base(options) { }

    protected override Kernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier == null )
        {
            throw new ArgumentException("An identifier for the language model must be specified.");
        }

        var builder = Kernel.CreateBuilder();

        if ( this.options.ApiEndpoint == null )
        {
            throw new ArgumentException("An API endpoint must be specified.");
        }

        if ( this.options.ApiKey == null )
        {
            throw new ArgumentException("An API key for the AI service must be specified.");
        }

        // Apparently the only way to configure the client timeout is to
        // explicitly construct the AzureOpenAI client object and
        // provide that to SK.
        var clientOptions = new AzureOpenAIClientOptions();

        clientOptions.NetworkTimeout = TimeSpan.FromMinutes(2);

        var apiClient = new AzureOpenAIClient(
            this.options.ApiEndpoint,
            new Azure.AzureKeyCredential(this.options.ApiKey),
            clientOptions);

        builder.AddAzureOpenAIChatCompletion(
            deploymentName: this.options.ModelIdentifier,
            azureOpenAIClient: apiClient);

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
