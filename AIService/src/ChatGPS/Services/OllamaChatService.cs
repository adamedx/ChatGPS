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
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.Ollama;
using Microsoft.Extensions.DependencyInjection;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class OllamaChatService : ChatService
{
    readonly Uri DefaultUri = new Uri("http://localhost:11434");

    internal OllamaChatService(AiOptions options, ILoggerFactory? loggerFactory = null, string? userAgent = null) : base(options, loggerFactory, userAgent) { }

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

        if ( this.options.ApiEndpoint == null || this.options.ApiEndpoint.ToString().Length == 0 )
        {
            this.options.ApiEndpoint = DefaultUri;
        }

        var builder = base.GetKernelBuilder();

#pragma warning disable SKEXP0070

        builder.AddOllamaChatCompletion(
            modelId : this.options.ModelIdentifier,
            serviceId : this.options.ServiceIdentifier,
            endpoint : this.options.ApiEndpoint);

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

