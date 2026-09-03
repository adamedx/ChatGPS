//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.Collections.Generic;
using System.ClientModel;
using System.ClientModel.Primitives;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Modulus.ChatGPS.Models;
using OpenAI;

namespace Modulus.ChatGPS.Services;

public class OpenAIChatService : ChatService
{
    internal OpenAIChatService(AiOptions options, ILoggerFactory? loggerFactory = null, string? userAgent = null) : base(options, loggerFactory, userAgent) { }

    protected override IAIKernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier is null )
        {
            throw new ArgumentException("A model identifier for the language model must be specified.");
        }

        if ( this.options.ApiKey is null )
        {
            throw new ArgumentException("An API key is required for the language model service.");
        }

        var cleartextKey = GetCompatibleApiKey(this.options.ApiKey, this.options.PlainTextApiKey);

        var clientOptions = new OpenAIClientOptions();

        clientOptions.Endpoint = this.options.ApiEndpoint ?? GetDefaultEndpoint();
        clientOptions.NetworkTimeout = TimeSpan.FromMinutes(2);
        clientOptions.RetryPolicy = new ClientRetryPolicy(3);

        var apiKeyCredential = new ApiKeyCredential(cleartextKey);

        var apiClient = new OpenAIClient(credential : apiKeyCredential, options : clientOptions);

        var chatClient = apiClient.GetChatClient(this.options.ModelIdentifier).AsIChatClient(); // AsIChatClient(modelId : this.options.ModelIdentifier);

        var newKernel = new AIKernel(chatClient);
/*
        var builder = base.GetKernelBuilder();

        var cleartextKey = GetCompatibleApiKey(this.options.ApiKey, this.options.PlainTextApiKey);

        if ( this.options.ApiEndpoint is null )
        {
            builder.AddOpenAIChatCompletion(
                modelId: this.options.ModelIdentifier,
                apiKey: cleartextKey);
        }
        else
        {
            builder.AddOpenAIChatCompletion(
                modelId: this.options.ModelIdentifier,
                endpoint : this.options.ApiEndpoint,
                apiKey: cleartextKey);
        }

        builder.Services.ConfigureHttpClientDefaults(c =>
        {
            // Configure throttling retry behavior
            c.AddStandardResilienceHandler(o =>
            {
                o.Retry.ShouldRetryAfterHeader = true;
                o.Retry.ShouldHandle = args => ValueTask.FromResult(args.Outcome.Result?.StatusCode is System.Net.HttpStatusCode.TooManyRequests);
            });

            // Set network timeout
            c.ConfigureHttpClient(httpClient =>
            {
                httpClient.Timeout = TimeSpan.FromMinutes(2);
            });
         });

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }
*/
        this.serviceKernel = newKernel;

        return newKernel;
    }
}
