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

// Making this a ps1 instead of a .cs file so dotnet build will not try to compile it :)

using System.Runtime.CompilerServices;

using Microsoft.Extensions.AI;
using Microsoft.ML.OnnxRuntimeGenAI;

namespace Modulus.ChatGPS.Addons;

public static class OnnxChatClientFactory
{
    public static IChatClient Create(string modelIdentifier, string modelPath)
    {
        return new OnnxChatClient(modelIdentifier, modelPath);
    }

    private sealed class OnnxChatClient : IChatClient
    {
        public OnnxChatClient(string modelIdentifier, string modelPath)
        {
            using var config = new Config(modelPath);
            config.ClearProviders();
            config.AppendProvider("dml");
            config.SetProviderOption("dml", "device_id", "0");

            this.model = new Model(config);
            this.tokenizer = new Tokenizer(this.model);
            this.modelIdentifier = modelIdentifier;
        }

        public ChatClientMetadata Metadata => new ChatClientMetadata("onnx", null);

        public object? GetService(Type serviceType, object? serviceKey = null)
        {
            return null;
        }

        public Task<ChatResponse> GetResponseAsync(
            IEnumerable<ChatMessage> chatMessages,
            ChatOptions? options = null,
            CancellationToken cancellationToken = default)
        {
            var prompt = string.Join(
                Environment.NewLine,
                chatMessages.Select(message => $"{message.Role}: {message.Text}"));

            using var parameters = new GeneratorParams(this.model);
            parameters.SetSearchOption("max_length", options?.MaxOutputTokens ?? 4096);

            using var generator = new Generator(this.model, parameters);
            generator.AppendTokenSequences(this.tokenizer.Encode(prompt));

            var response = new System.Text.StringBuilder();
            using var stream = this.tokenizer.CreateStream();

            while (!generator.IsDone())
            {
                cancellationToken.ThrowIfCancellationRequested();
                generator.GenerateNextToken();
                var tokens = generator.GetSequence(0);
                response.Append(stream.Decode(tokens[tokens.Length - 1]));
            }

            return Task.FromResult(new ChatResponse(
                new ChatMessage(ChatRole.Assistant, response.ToString())));
        }

        public async IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(
            IEnumerable<ChatMessage> chatMessages,
            ChatOptions? options = null,
            [EnumeratorCancellation] CancellationToken cancellationToken = default)
        {
            var response = await GetResponseAsync(chatMessages, options, cancellationToken)
                .ConfigureAwait(false);
            yield return new ChatResponseUpdate(ChatRole.Assistant, response.Text);
        }

        public void Dispose()
        {
            this.tokenizer.Dispose();
            this.model.Dispose();
        }

        private readonly Model model;
        private readonly Tokenizer tokenizer;
        private readonly string modelIdentifier;
    }
}
