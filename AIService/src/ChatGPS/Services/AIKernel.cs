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

using System.Reflection;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Services;

public class AIKernel : IAIKernel
{
    public AIKernel(Microsoft.Extensions.AI.IChatClient chatClient, Microsoft.Extensions.AI.ChatOptions? initialChatOptions = null)
    {
        this.chatClient = chatClient;
        this.initialChatOptions = initialChatOptions;
    }

    public async Task<Modulus.ChatGPS.Models.ChatMessage> GetNextChatMessageAsync(List<Modulus.ChatGPS.Models.ChatMessage> history, AiOptions options, bool? allowAgentAccess)
    {
        var nativeHistory = GetNativeHistory(history);

        var chatOptions = GetPromptExecutionSettings(options, allowAgentAccess);

        var response = await CreateAgent(allowAgentAccess).RunAsync(
            nativeHistory,
            null,
            new ChatClientAgentRunOptions(chatOptions)).ConfigureAwait(false);

        var result = new AIChatMessage(Microsoft.Extensions.AI.ChatRole.Assistant, response.Text ?? "Unknown response");

        return result.ToChatMessage();
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(AIChatFunction chatFunction, AiOptions options, Dictionary<string,object?>? functionArguments, bool? allowAgentAccess)
    {
        var renderedPrompt = chatFunction.RenderPrompt(functionArguments);

        var history = new List<Modulus.ChatGPS.Models.ChatMessage>
        {
            new Modulus.ChatGPS.Models.ChatMessage(SenderRole.User, renderedPrompt)
        };

        var chatOptions = GetPromptExecutionSettings(options, allowAgentAccess);

        var nativeHistory = GetNativeHistory(history);

        var response = await CreateAgent(allowAgentAccess).RunAsync(
            nativeHistory,
            null,
            new ChatClientAgentRunOptions(chatOptions)).ConfigureAwait(false);

        return new FunctionOutput(new AIFunctionResult(response.Text ?? "", typeof(string), null, null));
    }

    public AIChatFunction CreateFunctionFromPrompt(string definitionPrompt, AiOptions? options = null)
    {
        return new AIChatFunction(definitionPrompt);
    }

    public void AddLogger(ILoggerFactory? loggerFactory)
    {
        if ( loggerFactory is not null && ! this.hasLogger )
        {
            // May need to find a way to clear existing log providers
            this.chatClient = new ChatClientBuilder(this.chatClient).UseOpenTelemetry(loggerFactory).Build();
/*            var serviceCollection = new ServiceCollection();

            serviceCollection.AddSingleton<ILoggerFactory>(loggerFactory);

            serviceCollection.AddChatClient(this.chatClient);
 */
//            chatClient.Services.AddSingleton<ILoggerFactory>(loggerFactory);
            this.hasLogger = true;
        }
    }

    public void AddPlugin(Plugin plugin)
    {
        _ = CreateTools(new[] { plugin });
    }

    public void RemovePlugin(Plugin plugin)
    {
        if ( plugin.Name is not null )
        {
            var provider = PluginProvider.GetProviderByName(plugin.Name);

            if ( ! IsSupportedPlugin(plugin.Name) && ! IsPowerShellPlugin(provider) )
            {
                throw new NotImplementedException($"Function calling for plugin '{plugin.Name}' is not yet implemented.");
            }
        }
    }

    public void SetPluginTable(IPluginTable pluginTable)
    {
        this.pluginTable = pluginTable;
    }

    private ChatClientAgent CreateAgent(bool? allowAgentAccess)
    {
        var tools = allowAgentAccess == false ? new List<AITool>() : CreateTools(this.pluginTable?.Plugins);
        var functionInvokingClient = new FunctionInvokingChatClient(this.chatClient);

        return new ChatClientAgent(
            functionInvokingClient,
            null,
            "ChatGPS",
            null,
            tools,
            null,
            null);
    }

    private static bool IsSupportedPlugin(string name)
    {
        return string.Equals(name, "LocalContext", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "TimePlugin", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "FileIOPlugin", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "TextPlugin", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "DocumentPlugin", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "HttpPlugin", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "BraveSearch", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "DuckDuckGo", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(name, "Google", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsPowerShellPlugin(PluginProvider provider)
    {
        return provider is PowerShellPluginProvider;
    }

    private List<AITool> CreateTools(IEnumerable<Plugin>? plugins)
    {
        var tools = new List<AITool>();

        if ( plugins is null )
        {
            return tools;
        }

        foreach ( var plugin in plugins )
        {
            if ( plugin.Name is null )
            {
                throw new NotImplementedException($"Function calling for plugin '{plugin.Name}' is not yet implemented.");
            }

            var provider = PluginProvider.GetProviderByName(plugin.Name);

            if ( ! IsSupportedPlugin(plugin.Name) && ! IsPowerShellPlugin(provider) )
            {
                throw new NotImplementedException($"Function calling for plugin '{plugin.Name}' is not yet implemented.");
            }

            var nativePlugin = provider.GetNativeInstance(plugin.Parameters, this.pluginTable?.Context);

            foreach ( var method in nativePlugin.GetType().GetMethods(BindingFlags.Instance | BindingFlags.Public) )
            {
                if ( method.DeclaringType == typeof(object) || method.IsSpecialName )
                {
                    continue;
                }

                tools.Add(AIFunctionFactory.Create(method, nativePlugin, new AIFunctionFactoryOptions()));
            }
        }

        return tools;
    }


    private ChatOptions GetPromptExecutionSettings(AiOptions options, bool? allowAgentAccess)
    {
        // This supports providers that don't have a KernelBuilder extension that supports
        // parameters that other more "native" SK providers configure via the builder. Some
        // providers require parameters such as the modelId (!) to be configured through
        // PromptExecutionSettings.
        ChatOptions result = options.GetRequestOptions(this.initialChatOptions);

        if ( options.TokenLimit is not null )
        {
            var tokenLimit = options.TokenLimit > 0 ? options.TokenLimit : this.tokenLimitDefault;
            Logger.Log(string.Format("Setting token limit to {0}", tokenLimit));
            result.MaxOutputTokens = tokenLimit;
        }
        else
        {
            Logger.Log("No token limit");
        }

        var allowFunctionCall = ( allowAgentAccess is not null ) ? (bool) allowAgentAccess :
            ( options.AllowAgentAccess is not null ? (bool) options.AllowAgentAccess : false );

        result.ToolMode = allowFunctionCall ? ChatToolMode.Auto : ChatToolMode.None;

        return result;
    }

/*
    private Microsoft.Extensions.AI.ChatOptions GetPromptExecutionSettings(AiOptions options)
    {
        result = options.GetRequestOptions( options )
        OpenAIPromptExecutionSettings result;

        if ( this.initialPromptSettings is null )
        {
            result = new OpenAIPromptExecutionSettings();
        }
        else
        {
            // This supports providers that don't have a KernelBuilder extension that supports
            // parameters that other more "native" SK providers configure via the builder. Some
            // providers require parameters such as the modelId (!) to be configured through
            // PromptExecutionSettings.
            result = (OpenAIPromptExecutionSettings) this.initialPromptSettings.Clone();
        }

        if ( this.options.TokenLimit is not null )
        {
            var tokenLimit = this.options.TokenLimit > 0 ? this.options.TokenLimit : tokenLimitDefault;
            Logger.Log(string.Format("Setting token limit to {0}", tokenLimit));
            result.MaxTokens = tokenLimit;
        }
        else
        {
            Logger.Log("No token limit");
        }

        return result;
    }
*/

    private static List<Microsoft.Extensions.AI.ChatMessage> GetNativeHistory(List<Modulus.ChatGPS.Models.ChatMessage> sourceHistory)
    {
        var result = new List<Microsoft.Extensions.AI.ChatMessage>();

        foreach ( var sourceMessage in sourceHistory )
        {
            var nativeMessage = new Microsoft.Extensions.AI.ChatMessage( AIChatMessage.GetNativeRole(sourceMessage.Role), sourceMessage.Content );

            if ( sourceMessage.Metadata is not null )
            {
                nativeMessage.AdditionalProperties = new Microsoft.Extensions.AI.AdditionalPropertiesDictionary();

                foreach ( var key in sourceMessage.Metadata.Keys )
                {
                    nativeMessage.AdditionalProperties.Add(key, sourceMessage.Metadata[key]);
                }

                nativeMessage.AdditionalProperties = null;
            }
            else
            {
                nativeMessage.AdditionalProperties = null;
            }

            result.Add(nativeMessage);
        }

        return result;
    }

    private Microsoft.Extensions.AI.IChatClient chatClient;
    private Microsoft.Extensions.AI.ChatOptions? initialChatOptions = null;
    private IPluginTable? pluginTable;
    private int tokenLimitDefault = 4096;
    private bool hasLogger = false;
}
