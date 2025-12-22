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


internal class ConversationBuilder
{
    internal ConversationBuilder(IChatService chatService)
    {
        this.chatService = chatService;
    }

    internal List<ChatMessage> CreateConversationHistory(string systemPrompt)
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

    internal async Task<string> SendMessageAsync(List<ChatMessage> chatHistory, bool? allowAgentAccess = null)
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

    internal async Task<string> InvokeFunctionAsync(List<ChatMessage> chatHistory, Function chatFunction, string? prompt = null, bool? allowAgentAccess = null)
    {
        var targetPrompt = prompt is not null ? prompt : chatHistory[chatHistory.Count - 1].Content;

        if ( prompt is not null )
        {
            AddMessageToConversation(chatHistory, SenderRole.User, prompt, new TimeSpan(0));
        }

        var stopWatch = new Stopwatch();

        stopWatch.Start();

        var resultString = await chatFunction.InvokeFunctionAsync(this.chatService, new () { ["input"] = targetPrompt }, allowAgentAccess );

        stopWatch.Stop();

        string targetResult = resultString is not null ? resultString : "I was unable to respond to your message.";

        UpdateHistoryWithResponse(chatHistory, targetResult, stopWatch.Elapsed);

        return targetResult;
    }

    internal void AddMessageToConversation(List<ChatMessage> chatHistory, SenderRole role, string prompt, TimeSpan duration)
    {
        var targetProperties = CreateMessageProperties(duration);

        chatHistory.Add(new ChatMessage(role, prompt, targetProperties));
    }

    internal void AddMessageToConversation(List<ChatMessage> chatHistory, SenderRole role, string prompt, IReadOnlyDictionary<string,string?>? messageProperties = null)
    {
        var targetProperties = messageProperties is not null ? messageProperties : CreateMessageProperties();
        chatHistory.Add(new ChatMessage(role, prompt, targetProperties));
    }

    static internal void CopyMessageToConversation(List<ChatMessage> destinationHistory, List<ChatMessage> sourceHistory, int messageIndex)
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

        destinationHistory.Add(new ChatMessage(sourceHistory[messageIndex].Role, content, sourceHistory[messageIndex].Metadata));
    }

    internal void UpdateHistoryWithResponse(List<ChatMessage> chatHistory, string response, TimeSpan duration)
    {
        AddMessageToConversation(chatHistory, SenderRole.Assistant, response, duration);
    }

    internal void UpdateHistoryWithResponse(List<ChatMessage> chatHistory, string response)
    {
        AddMessageToConversation(chatHistory, SenderRole.Assistant, response);
    }

    private Dictionary<string,string?>? CreateMessageProperties(TimeSpan? duration = null)
    {
        var dictionary = new Dictionary<string,string?>
        {
            { MetadataKeys.Timestamp.ToString(), JsonSerializer.Serialize<DateTimeOffset>(DateTimeOffset.Now) },
            { MetadataKeys.MessageIndex.ToString(), JsonSerializer.Serialize<int>(this.messageIndex++) },
            { MetadataKeys.Duration.ToString(), JsonSerializer.Serialize<TimeSpan?>(duration) }
        };

        return new Dictionary<string,string?>(dictionary);
    }

    private IChatService chatService;

    private int messageIndex = 0;
}
