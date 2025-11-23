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

namespace Modulus.ChatGPS.Models;

internal class AIChatMessage : IChatMessage
{
    static AIChatMessage()
    {
        AIChatMessage.roleMap = new Dictionary<ChatRole,SenderRole>()
        {
            { ChatRole.Assistant, SenderRole.Assistant },
            { ChatRole.System, SenderRole.System },
            { ChatRole.Tool, SenderRole.Tool },
            { ChatRole.User, SenderRole.User }
        };

        AIChatMessage.reverseRoleMap = new Dictionary<SenderRole,ChatRole>();

        foreach ( var chatRole in AIChatMessage.roleMap.Keys )
        {
            AIChatMessage.reverseRoleMap.Add(AIChatMessage.roleMap[chatRole], chatRole);
        }
    }

    internal AIChatMessage(Microsoft.Extensions.AI.ChatMessage sourceMessage)
    {
        this.NativeRole = sourceMessage.Role;
        this.Content = sourceMessage.Text;

        if ( sourceMessage.AdditionalProperties is not null )
        {
            this.Metadata = new Dictionary<string,string?>();

            foreach ( var key in sourceMessage.AdditionalProperties.Keys )
            {
                this.Metadata.Add(key, sourceMessage.AdditionalProperties[key]?.ToString());
            }
        }
        else
        {
            this.Metadata = new Dictionary<string,string?>();
        }
    }

    internal AIChatMessage(ChatRole role, string content, IReadOnlyDictionary<string,string?>? metadata = null)
    {
        this.NativeRole = role;
        this.Content = content;
        this.Metadata = metadata is not null ? new Dictionary<string,string?>(metadata) : new Dictionary<string,string?>();
    }

    internal AIChatMessage(ChatRole role, string content, AdditionalPropertiesDictionary additionalProperties)
    {
        this.NativeRole = role;
        this.Content = content;

        this.Metadata = new Dictionary<string,string?>();

        foreach ( var key in additionalProperties.Keys )
        {
            this.Metadata.Add(key, additionalProperties[key]?.ToString());
        }
    }

    internal ChatMessage ToChatMessage()
    {
        return new ChatMessage( this.Role, this.Content, this.Metadata );
    }

    public string Content { get; set; }

    public Microsoft.Extensions.AI.ChatRole NativeRole { get; set; }

    public SenderRole Role {
        get
        {
            return AIChatMessage.roleMap[this.NativeRole];
        }
        set
        {
            this.nativeRole = AIChatMessage.reverseRoleMap[value];
        }
    }

    public Dictionary<string,string?> Metadata { get; set; }

    public static ChatRole GetNativeRole( SenderRole role )
    {
        return AIChatMessage.reverseRoleMap[role];
    }

    private static IDictionary<ChatRole, SenderRole> roleMap;
    private static IDictionary<SenderRole, ChatRole> reverseRoleMap;
    private Microsoft.Extensions.AI.ChatRole nativeRole;
}
