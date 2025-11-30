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

using System.Collections.ObjectModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.AI;

namespace Modulus.ChatGPS.Models;

public class ChatMessage
{
    public enum MetadataKeys
    {
        MessageIndex,
        Timestamp,
        Duration
    }

    public enum SenderRole
    {
        Assistant,
        System,
        Tool,
        User,
        Unknown
    }

    static ChatMessage()
    {
        ChatMessage.roleMap = new Dictionary<ChatRole,SenderRole>()
        {
            { ChatRole.Assistant, SenderRole.Assistant },
            { ChatRole.System, SenderRole.System },
            { ChatRole.Tool, SenderRole.Tool },
            { ChatRole.User, SenderRole.User }
        };

        ChatMessage.reverseRoleMap = new Dictionary<SenderRole,ChatRole>();

        foreach ( var chatRole in ChatMessage.roleMap.Keys )
        {
            ChatMessage.reverseRoleMap.Add(ChatMessage.roleMap[chatRole], chatRole);
        }
    }

    public ChatMessage(SenderRole role, string content, Dictionary<string,object?>? metadata = null)
    {
        this.sourceMessage2 = new AIChatMessage(ChatMessage.reverseRoleMap[role], content, metadata);
    }

    internal ChatMessage(Microsoft.Extensions.AI.ChatMessage sourceChatMessage)
    {
        this.sourceMessage2 = new AIChatMessage(sourceChatMessage);
    }

    internal ChatMessage(Microsoft.Extensions.AI.ChatResponse chatResponse)
    {
        var firstMessage = chatResponse.Messages.FirstOrDefault();

        this.sourceMessage2 = new AIChatMessage(firstMessage?.Role ?? ChatRole.Assistant, chatResponse.Text ?? "", chatResponse.AdditionalProperties);
    }

    public SenderRole Role
    {
        get
        {
            SenderRole senderRole;

            if ( ! ChatMessage.roleMap.TryGetValue(this.sourceMessage2.Role, out senderRole) )
            {
                senderRole = SenderRole.Unknown;
            }

            return senderRole;
        }
    }

    public string? Content
    {
        get
        {
            return this.sourceMessage2.Content;
        }
    }

    private System.Collections.Generic.IReadOnlyDictionary<string,object?>? Metadata
    {
        get
        {
            return this.sourceMessage2.Metadata;
        }
    }

    public System.Text.Encoding Encoding
    {
        get
        {
            return this.sourceMessage2.Encoding;
        }
    }

    public TimeSpan? Duration
    {
        get
        {
            TimeSpan? result = null;

            if ( this.sourceMessage2.Metadata is not null )
            {
                object? duration = null;

                if ( this.sourceMessage2.Metadata.TryGetValue(MetadataKeys.Duration.ToString(), out duration) )
                {
                    if ( duration is not null )
                    {
                        result = JsonSerializer.Deserialize<TimeSpan?>((string) duration);
                    }
                }
            }

            return result;
        }
    }

    public DateTimeOffset Timestamp
    {
        get
        {
            DateTimeOffset result = DateTimeOffset.MinValue;

            if ( this.sourceMessage2.Metadata is not null )
            {
                object? timestamp = null;

                if ( this.sourceMessage2.Metadata.TryGetValue(MetadataKeys.Timestamp.ToString(), out timestamp) )
                {
                    if ( timestamp is not null )
                    {
                        result = JsonSerializer.Deserialize<DateTimeOffset>((string) timestamp);
                    }
                }
            }

            return result;
        }
    }

    public object GetSourceChatMessageContent()
    {
        return this.SourceChatMessageContent2;
    }

    internal Microsoft.Extensions.AI.ChatMessage SourceChatMessageContent2
    {
        get
        {
            return new Microsoft.Extensions.AI.ChatMessage();
        }
    }

    private AIChatMessage sourceMessage2;

    private static IDictionary<ChatRole, SenderRole> roleMap;
    private static IDictionary<SenderRole, ChatRole> reverseRoleMap;
}
