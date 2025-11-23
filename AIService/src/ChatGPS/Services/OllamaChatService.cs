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

using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class OllamaChatService : ChatService
{
    internal OllamaChatService(AiOptions options, ILoggerFactory? loggerFactory = null, string? userAgent = null) : base(options, loggerFactory, userAgent) { }


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

        var endpoint = this.options.ApiEndpoint ?? DefaultUri;

        var chatClient = new OllamaChatClient(endpoint, this.options.ModelIdentifier);

        var newKernel = new AIKernel(chatClient);

        this.serviceKernel = newKernel;

        return newKernel;
    }


    readonly Uri DefaultUri = new Uri("http://localhost:11434");
}

