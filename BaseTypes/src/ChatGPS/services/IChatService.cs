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


using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Services;

public interface IChatService
{
    public List<ChatMessage> CreateChat(string prompt);
    public Task<IReadOnlyList<ChatMessage>> GetChatCompletionAsync(List<ChatMessage> history, bool? allowAgentAccess = null);
    public Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string, object?>? parameters, bool? allowFunctionCall);
    public AiOptions ServiceOptions { get; }
    public IPluginTable Plugins { get; }
}
