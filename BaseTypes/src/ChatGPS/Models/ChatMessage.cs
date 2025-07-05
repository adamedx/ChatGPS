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
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

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
        ChatMessage.roleMap = new Dictionary<AuthorRole,SenderRole>()
        {
            { AuthorRole.Assistant, SenderRole.Assistant },
            { AuthorRole.System, SenderRole.System },
            { AuthorRole.Tool, SenderRole.Tool },
            { AuthorRole.User, SenderRole.User }
        };

        ChatMessage.reverseRoleMap = new Dictionary<SenderRole,AuthorRole>();

        foreach ( var authorRole in ChatMessage.roleMap.Keys )
        {
            ChatMessage.reverseRoleMap.Add(ChatMessage.roleMap[authorRole], authorRole);
        }
    }

    public ChatMessage(SenderRole role, string content, Dictionary<string,object?>? metadata = null)
    {
        this.sourceMessage = new ChatMessageContent(ChatMessage.reverseRoleMap[role], content, null, null, null, metadata);
    }

    public ChatMessage(ChatMessageContent sourceMessage)
    {
        this.sourceMessage = sourceMessage;
    }

    public SenderRole Role
    {
        get
        {
            SenderRole senderRole;

            if ( ! ChatMessage.roleMap.TryGetValue(this.sourceMessage.Role, out senderRole) )
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
            return this.sourceMessage.Content;
        }
    }

    private System.Collections.Generic.IReadOnlyDictionary<string,object?>? Metadata
    {
        get
        {
            return this.sourceMessage.Metadata;
        }
    }

    public System.Text.Encoding Encoding
    {
        get
        {
            return this.sourceMessage.Encoding;
        }
    }

    public TimeSpan? Duration
    {
        get
        {
            TimeSpan? result = null;

            if ( this.sourceMessage.Metadata is not null )
            {
                object? duration = null;

                if ( this.sourceMessage.Metadata.TryGetValue(MetadataKeys.Duration.ToString(), out duration) )
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

            if ( this.sourceMessage.Metadata is not null )
            {
                object? timestamp = null;

                if ( this.sourceMessage.Metadata.TryGetValue(MetadataKeys.Timestamp.ToString(), out timestamp) )
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
        return this.SourceChatMessageContent;
    }

    internal ChatMessageContent SourceChatMessageContent
    {
        get
        {
            return sourceMessage;
        }
    }

    private ChatMessageContent sourceMessage;

    private static IDictionary<AuthorRole, SenderRole> roleMap;
    private static IDictionary<SenderRole, AuthorRole> reverseRoleMap;
}

