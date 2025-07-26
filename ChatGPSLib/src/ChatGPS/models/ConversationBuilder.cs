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

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

internal class ConversationBuilder
{
    internal ConversationBuilder(IChatService chatService)
    {
        this.chatService = chatService;
    }

    internal ChatHistory CreateConversationHistory(string systemPrompt)
    {
        var history = this.chatService.CreateChat(systemPrompt);

        history[0].Metadata = CreateMessageProperties(new TimeSpan(0));

        return history;
    }

    internal IChatService AIService
    {
        get
        {
            return this.chatService;
        }
    }

    internal async Task<string> SendMessageAsync(ChatHistory chatHistory, bool? allowAgentAccess = null)
    {
        var stopWatch = new Stopwatch();

        stopWatch.Start();

        var responses = await this.chatService.GetChatCompletionAsync(chatHistory, allowAgentAccess);

        stopWatch.Stop();

        string results = "";

        foreach ( var response in responses )
        {
            if ( response is not null && response.Content is not null )
            {
                results += response.Content;
                UpdateHistoryWithResponse(chatHistory, response.Content, stopWatch.Elapsed);
            }
        }

        return results;
    }

    internal async Task<string> InvokeFunctionAsync(ChatHistory chatHistory, Function chatFunction, string? prompt = null, bool? allowAgentAccess = null)
    {
        var targetPrompt = prompt is not null ? prompt : chatHistory[chatHistory.Count - 1].Content;

        if ( prompt is not null )
        {
            AddMessageToConversation(chatHistory, AuthorRole.User, prompt, new TimeSpan(0));
        }

        var stopWatch = new Stopwatch();

        stopWatch.Start();

        var resultString = await chatFunction.InvokeFunctionAsync(this.chatService, new () { ["input"] = targetPrompt }, allowAgentAccess );

        stopWatch.Stop();

        string targetResult = resultString is not null ? resultString : "I was unable to respond to your message.";

        UpdateHistoryWithResponse(chatHistory, targetResult, stopWatch.Elapsed);

        return targetResult;
    }

    internal void AddMessageToConversation(ChatHistory chatHistory, AuthorRole role, string prompt, TimeSpan duration)
    {
        var targetProperties = CreateMessageProperties(duration);

        chatHistory.AddMessage(role, prompt, null, targetProperties);
    }

    internal void AddMessageToConversation(ChatHistory chatHistory, AuthorRole role, string prompt, IReadOnlyDictionary<string,object?>? messageProperties = null)
    {
        var targetProperties = messageProperties is not null ? messageProperties : CreateMessageProperties();
        chatHistory.AddMessage(role, prompt, null, targetProperties);
    }

    static internal void CopyMessageToConversation(ChatHistory destinationHistory, ChatHistory sourceHistory, int messageIndex)
    {
        if ( sourceHistory[messageIndex].Role == destinationHistory[destinationHistory.Count - 1].Role )
        {
            var targetRole = destinationHistory[destinationHistory.Count - 1].Role;
            var targetMessage = destinationHistory[destinationHistory.Count - 1].Content;
            var sourceMessage = sourceHistory[messageIndex].Content;

            throw new ArgumentException(String.Format("Mismatch in destination {0}. Target = {1}, Source = {2}", targetRole, targetMessage, sourceMessage));
        }

        var  content = sourceHistory[messageIndex].Content;

        if ( content is null )
        {
            throw new ArgumentException("Unexpected null content in message");
        }

        destinationHistory.AddMessage(sourceHistory[messageIndex].Role, content, null, sourceHistory[messageIndex].Metadata);
    }

    internal void UpdateHistoryWithResponse(ChatHistory chatHistory, string response, TimeSpan duration)
    {
        AddMessageToConversation(chatHistory, AuthorRole.Assistant, response, duration);
    }

    internal void UpdateHistoryWithResponse(ChatHistory chatHistory, string response)
    {
        AddMessageToConversation(chatHistory, AuthorRole.Assistant, response);
    }

    private ReadOnlyDictionary<string,object?>? CreateMessageProperties(TimeSpan? duration = null)
    {
        var dictionary = new Dictionary<string,object?>
        {
            { ChatMessage.MetadataKeys.Timestamp.ToString(), JsonSerializer.Serialize<DateTimeOffset>(DateTimeOffset.Now) },
            { ChatMessage.MetadataKeys.MessageIndex.ToString(), JsonSerializer.Serialize<int>(this.messageIndex++) },
            { ChatMessage.MetadataKeys.Duration.ToString(), JsonSerializer.Serialize<TimeSpan?>(duration) }
        };

        return new ReadOnlyDictionary<string,object?>(dictionary);
    }

    private IChatService chatService;

    private int messageIndex = 0;
}
