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

public class AIKernel : IAIKernel
{
    internal AIKernel(Microsoft.Extensions.AI.IChatClient chatClient, Microsoft.Extensions.AI.ChatOptions? chatOptions)
    {
        this.chatClient = chatClient;
        this.chatOptions = chatOptions;
    }

    public async Task<ChatMessage> GetNextChatMessageAsync(ChatMessageHistory history, AiOptions options, bool? allowAgentAccess)
    {
        var nativeHistory = history.SourceHistory;

        var response = await chatClient.GetResponseAsync(
            nativeHistory, chatOptions);

        var result = new ChatMessage(response);

        return result;
    }

	public Task<FunctionOutput> InvokeFunctionAsync(AIChatFunction chatFunction, AiOptions options, Dictionary<string,object>? functionArguments, bool? allowAgentAccess)
    {
        throw new NotImplementedException("Chat functions are not yet implemented");
    }

    public void AddPlugin(Plugin plugin)
    {
        throw new NotImplementedException("Plugins are not yet implemented");
    }

    public void RemovePlugin(Plugin plugin)
    {
        throw new NotImplementedException("Plugins are not yet implemented");
    }


    private Microsoft.Extensions.AI.IChatClient chatClient;
    private Microsoft.Extensions.AI.ChatOptions? chatOptions;
}

