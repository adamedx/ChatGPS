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

public interface IAIKernel
{
	Task<ChatMessage> GetNextChatMessageAsync(List<ChatMessage> history, AiOptions options, bool? allowAgentAccess = null);
	Task<FunctionOutput> InvokeFunctionAsync(AIChatFunction chatFunction, AiOptions options, Dictionary<string,object?>? functionArguments = null, bool? allowAgentAccess = null);
    AIChatFunction CreateFunctionFromPrompt(string definitionPrompt, AiOptions? options = null);
    void SetPluginTable(IPluginTable pluginTable);
}
