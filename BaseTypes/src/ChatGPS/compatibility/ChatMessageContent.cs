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

namespace Modulus.ChatGPS.Compatibility;


public class ChatMessageContent
{
    public AuthorRole Role { get; set; }

    public string? Content
    {
        get
        {
            var textContent = this.Items.OfType<string>().FirstOrDefault();
            return textContent;
        }
        set
        {
            var textContent = this.Items.OfType<string>().FirstOrDefault();
            if (textContent is null && value is not null)
            {
                this.Items.Add(value);
            }
        }
    }

    /// <summary>
    /// Chat message content items
    /// </summary>
    public IList<string> Items
    {
        get => this._items ??= [];
        set => this._items = value;
    }

    public IReadOnlyDictionary<string, object?>? Metadata { get; set; }

    public ChatMessageContent()
    {
    }

    public ChatMessageContent(
        AuthorRole role,
        string? content,
        IReadOnlyDictionary<string, object?>? metadata = null)
    {
        this.Role = role;
        this.metadata = metadata;
        this.Content = content;
    }

    public ChatMessageContent(
        AuthorRole role,
        IList<string> items,
        IReadOnlyDictionary<string, object?>? metadata = null)
    {
        this.Role = role;
        this.metadata = metadata;
        this._items = items;
    }

    public override string ToString()
    {
        return this.Content ?? string.Empty;
    }

    private IList<string>? _items;
}

