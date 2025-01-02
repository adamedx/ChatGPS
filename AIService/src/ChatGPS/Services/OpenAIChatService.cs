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

        if ( this.options.DeploymentName == null )
        {
            throw new ArgumentException("A deployment name for the language model must be specified.");
        }

        var builder = Kernel.CreateBuilder();

        if ( this.options.ApiEndpoint == null )
        {
            throw new ArgumentException("An API endpoint must be specified.");
        }

        // Apparently the only way to configure the client timeout is to
        // explicitly construct the AzureOpenAI client object and
        // provide that to SK.
        var clientOptions = new AzureOpenAIClientOptions();

        clientOptions.NetworkTimeout = TimeSpan.FromMinutes(2);

        AzureOpenAIClient apiClient;

        if ( this.options.ApiKey is not null && this.options.ApiKey.Length > 0 )
        {
            apiClient = new AzureOpenAIClient(
                this.options.ApiEndpoint,
                new Azure.AzureKeyCredential(this.options.ApiKey),
                clientOptions);
        }
        else
        {
            // Use the default Azure credential when there is no API key -- this
            // requires that the user has already signed in using a mechanism
            // such as the Login-AzAccount command.
            var signinInteractionAllowed = this.options.SigninInteractionAllowed ?? false;

            apiClient = new AzureOpenAIClient(
                this.options.ApiEndpoint,
                new Azure.Identity.DefaultAzureCredential(signinInteractionAllowed),
                clientOptions);
        }

        builder.AddAzureOpenAIChatCompletion(
            deploymentName: this.options.DeploymentName,
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
