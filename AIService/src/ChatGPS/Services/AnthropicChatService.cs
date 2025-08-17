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

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

using Anthropic.SDK;

namespace Modulus.ChatGPS.Services;

public class AnthropicChatService : ChatService
{
    internal AnthropicChatService(AiOptions options, ILoggerFactory? loggerFactory = null) : base(options, loggerFactory) { }

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

        if ( this.options.ApiKey is null )
        {
            throw new ArgumentException("An API key is required for the language model service.");
        }

        var cleartextKey = GetCompatibleApiKey(this.options.ApiKey, this.options.PlainTextApiKey);

        var apiKey = new APIAuthentication( cleartextKey );

        this.initialPromptSettings = new OpenAIPromptExecutionSettings()
        {
            ModelId = this.options.ModelIdentifier
        };

        var builder = base.GetKernelBuilder();

        // Configure throttling retry behavior
        builder.Services.ConfigureHttpClientDefaults(c =>
        {
            c.AddStandardResilienceHandler(o =>
            {
                o.Retry.ShouldRetryAfterHeader = true;
                o.Retry.ShouldHandle = args => ValueTask.FromResult(args.Outcome.Result?.StatusCode is System.Net.HttpStatusCode.TooManyRequests);
            });
        });

#pragma warning disable SKEXP0001
        builder.Services.AddSingleton<IChatCompletionService>((serviceProvider) => new AnthropicClient(apiKey).Messages.AsChatCompletionService());
#pragma warning restore SKEXP0001

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
    }
}
