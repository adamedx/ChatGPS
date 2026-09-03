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

using Modulus.ChatGPS.Models;

using Anthropic.SDK;

namespace Modulus.ChatGPS.Services;

public class AnthropicChatService : ChatService
{
    internal AnthropicChatService(AiOptions options, ILoggerFactory? loggerFactory = null) : base(options, loggerFactory) { }

    protected override IAIKernel GetKernel()
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

        var httpClient = new HttpClient(new AnthropicRetryHandler())
        {
            Timeout = TimeSpan.FromMinutes(2)
        };

        var chatClient = (IChatClient) new AnthropicClient(apiKey, httpClient).Messages;

        var newKernel = new AIKernel(chatClient);

        this.serviceKernel = newKernel;

        return newKernel;
    }
}

