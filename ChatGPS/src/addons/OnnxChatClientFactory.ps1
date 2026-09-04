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

// Making this a ps1 instead of a .cs file so dotnet build will not try to compile it,
// and the PowerShell module packaging mechanism will continue to include it :)

using System.Runtime.CompilerServices;

using Microsoft.Extensions.AI;
using Microsoft.ML.OnnxRuntimeGenAI;

namespace Modulus.ChatGPS.Addons;

public static class OnnxChatClientFactory
{
    public static IChatClient Create(
        string modelIdentifier,
        string modelPath,
        string? localModelProvider,
        Dictionary<string, string>? localModelProviderOptions)
    {
        return new OnnxChatClient(
            modelIdentifier,
            modelPath,
            localModelProvider,
            localModelProviderOptions);
    }

    private sealed class OnnxChatClient : IChatClient
    {
        public OnnxChatClient(
            string modelIdentifier,
            string modelPath,
            string? localModelProvider,
            Dictionary<string, string>? localModelProviderOptions)
        {
            using var config = new Config(modelPath);

            if (!string.IsNullOrWhiteSpace(localModelProvider))
            {
                config.ClearProviders();
                config.AppendProvider(localModelProvider);

                if (localModelProviderOptions is not null &&
                    localModelProviderOptions.ContainsKey("Provider"))
                {
                    foreach (var option in localModelProviderOptions)
                    {
                        config.SetProviderOption(localModelProvider, option.Key, option.Value);
                    }
                }
            }

            this.model = new Model(config);
            this.tokenizer = new Tokenizer(this.model);
            this.chatTemplate = LoadChatTemplate(modelPath);
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
            var prompt = this.tokenizer.ApplyChatTemplate(
                this.chatTemplate,
                BuildMessagesJson(chatMessages),
                string.Empty,
                true);

            var promptTokens = this.tokenizer.Encode(prompt);
            var maxOutputTokens = options?.MaxOutputTokens ?? 4096;
            // ONNX Runtime GenAI's max_length includes the prompt tokens.
            var maxSequenceLength = checked(promptTokens[0].Length + Math.Max(1, maxOutputTokens));

            using var parameters = new GeneratorParams(this.model);
            parameters.SetSearchOption("max_length", maxSequenceLength);

            using var generator = new Generator(this.model, parameters);
            generator.AppendTokenSequences(promptTokens);

            var response = new System.Text.StringBuilder();
            using var stream = this.tokenizer.CreateStream();

            while ( ! generator.IsDone() )
            {
                cancellationToken.ThrowIfCancellationRequested();
                generator.GenerateNextToken();
                var tokens = generator.GetSequence( 0 );
                response.Append(stream.Decode( tokens[tokens.Length - 1]) );
            }

            return Task.FromResult(new ChatResponse( new ChatMessage(ChatRole.Assistant, response.ToString())) );
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

        private static string BuildMessagesJson(IEnumerable<ChatMessage> chatMessages)
        {
            var messages = new List<object>();

            foreach (var message in chatMessages)
            {
                var role = message.Role.ToString().ToLowerInvariant();

                if (role is not ("system" or "user" or "assistant"))
                {
                    continue;
                }

                messages.Add(new
                {
                    role,
                    content = message.Text ?? string.Empty
                });
            }

            return System.Text.Json.JsonSerializer.Serialize(messages);
        }

        private static string LoadChatTemplate(string modelPath)
        {
            var tokenizerConfigPath = Path.Combine(modelPath, "tokenizer_config.json");

            if (!File.Exists(tokenizerConfigPath))
            {
                throw new InvalidOperationException(
                    $"The ONNX model does not contain the required tokenizer configuration file '{tokenizerConfigPath}'.");
            }

            using var document = System.Text.Json.JsonDocument.Parse(File.ReadAllText(tokenizerConfigPath));

            if (!document.RootElement.TryGetProperty("chat_template", out var chatTemplate) ||
                chatTemplate.ValueKind != System.Text.Json.JsonValueKind.String ||
                string.IsNullOrWhiteSpace(chatTemplate.GetString()))
            {
                throw new InvalidOperationException(
                    $"The ONNX model tokenizer configuration '{tokenizerConfigPath}' does not define a chat_template.");
            }

            return chatTemplate.GetString()!;
        }

        private readonly Model model;
        private readonly Tokenizer tokenizer;
        private readonly string chatTemplate;
        private readonly string modelIdentifier;
    }
}
