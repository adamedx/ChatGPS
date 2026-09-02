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

        var response = await chatClient.GetResponseAsync(
            nativeHistory, chatOptions);

        var nativeMessage = response.Messages.FirstOrDefault();

        var result = nativeMessage is not null ? new AIChatMessage(nativeMessage) : new AIChatMessage(Microsoft.Extensions.AI.ChatRole.Assistant, "Unknown response");

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

        var response = await this.chatClient.GetResponseAsync(
            nativeHistory, chatOptions).ConfigureAwait(false);

        var nativeMessage = response.Messages.FirstOrDefault();

        var resultText = nativeMessage is not null ? (nativeMessage.Text ?? "") : "";

        return new FunctionOutput(new AIFunctionResult(resultText, typeof(string), null, null));
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
        throw new NotImplementedException("Plugins are not yet implemented");
    }

    public void RemovePlugin(Plugin plugin)
    {
        throw new NotImplementedException("Plugins are not yet implemented");
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
    private int tokenLimitDefault = 4096;
    private bool hasLogger = false;
}

