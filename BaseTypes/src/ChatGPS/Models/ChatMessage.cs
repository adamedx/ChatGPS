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

namespace Modulus.ChatGPS.Models;

public class ChatMessage : IChatMessage
{
    public ChatMessage()
    {
        this.metadata = new Dictionary<string,string?>();
    }

    public ChatMessage(SenderRole role, string content, IReadOnlyDictionary<string,string?>? metadata = null)
    {
        this.Role = role;
        this.Content = content;
        this.metadata = metadata is not null ? ((Dictionary<string,string?>)metadata) : new Dictionary<string,string?>();
    }

    internal ChatMessage(IChatMessage sourceMessage)
    {
        this.Role = sourceMessage.Role;
        this.Content = sourceMessage.Content;
        this.metadata = sourceMessage.Metadata is not null ? ((Dictionary<string,string?>) sourceMessage.Metadata) : new Dictionary<string,string?>();
    }

    public SenderRole Role { get; set; }

    public string? Content { get; set; }

    public System.Collections.Generic.Dictionary<string,string?>? Metadata
    {
        get
        {
            return this.metadata;
        }

        set
        {
            if ( value is not null )
            {
                this.metadata = new Dictionary<string,string?>(value);
            }
            else
            {
                this.metadata = new Dictionary<string,string?>();
            }
        }
    }

    public TimeSpan? Duration
    {
        get
        {
            TimeSpan? result = null;

            if ( this.Metadata is not null )
            {
                string? duration = null;

                if ( this.Metadata.TryGetValue(MetadataKeys.Duration.ToString(), out duration) )
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

            if ( this.Metadata is not null )
            {
                string? timestamp = null;

                if ( this.Metadata.TryGetValue(MetadataKeys.Timestamp.ToString(), out timestamp) )
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

    private Dictionary<string,string?> metadata;
}
