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

internal class AIChatMessage
{
    internal AIChatMessage(Microsoft.Extensions.AI.ChatMessage sourceMessage)
    {
        this.Role = sourceMessage.Role;
        this.Content = sourceMessage.Text;

        if ( sourceMessage.AdditionalProperties is not null )
        {
            this.Metadata = new Dictionary<string,object?>(sourceMessage.AdditionalProperties);
        }
        else
        {
            this.Metadata = new Dictionary<string,object?>();
        }
    }

    internal AIChatMessage(ChatRole role, string content, Dictionary<string,object?>? metadata = null)
    {
        this.Role = role;
        this.Content = content;
        this.Metadata = metadata is not null ? new Dictionary<string,object?>(metadata) : new Dictionary<string,object?>();
    }

    internal AIChatMessage(ChatRole role, string content, AdditionalPropertiesDictionary? additionalProperties = null)
    {
        this.Role = role;
        this.Content = content;
        this.Metadata = additionalProperties is not null ? new Dictionary<string,object?>(additionalProperties) : new Dictionary<string,object?>();
    }

    internal string Content { get; private set; }

    internal Microsoft.Extensions.AI.ChatRole Role { get; private set; }

    internal System.Text.Encoding Encoding
    {
        get
        {
            return System.Text.Encoding.UTF8;
        }
    }

    internal Dictionary<string,object?> Metadata { get; private set; }
}
