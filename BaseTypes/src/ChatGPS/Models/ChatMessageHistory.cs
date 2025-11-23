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
using Modulus.ChatGPS.Services;

namespace Modulus.ChatGPS.Models;
/*
public class ChatMessageHistory : System.Collections.Generic.IList<IChatMessage>,
    System.Collections.Generic.ICollection<IChatMessage>,
    System.Collections.Generic.IEnumerable<IChatMessage>
{
    public ChatMessageHistory()
    {
        this.sourceHistory = new List<IChatMessage>();
    }

    public ChatMessageHistory(ChatMessageHistory sourceHistory)
    {
        this.sourceHistory = new List<IChatMessage>(sourceHistory.sourceHistory);
    }

    public ChatMessageHistory( System.Collections.Generic.IList<IChatMessage> sourceHistory )
    {
        this.sourceHistory = sourceHistory;
    }

    public ChatMessageHistory(string systemPrompt)
    {
        this.sourceHistory = new List<IChatMessage>();

        var systemMessage = new ChatMessage(SenderRole.System, systemPrompt);

        this.Add(systemMessage);
    }

    public IChatMessage this[int index]
    {
        get
        {
            var privateItem = this.sourceHistory[index];

            var publicItem = GetPublicItem(privateItem);

            if ( publicItem is null )
            {
                throw new ArgumentException("Object state is invalid");
            }

            return publicItem;
        }

        set
        {
            var sourceItem = ((ChatMessage)value).SourceChatMessageContent2;

            if ( sourceItem is null )
            {
                throw new ArgumentException("Enumerated item is invalid");
            }

            var currentIndex = this.sourceHistory.IndexOf(sourceItem);

            if ( currentIndex != -1 )
            {
                this.sourceHistory[index] = sourceItem;
            }
            else if ( currentIndex != index )
            {
                throw new InvalidOperationException("The key already exists at another location in the collection");
            }
        }
    }

    public int IndexOf(IChatMessage chatMessage)
    {
        var sourceItem = ((ChatMessage)chatMessage).SourceChatMessageContent2;

        if ( sourceItem is null )
        {
            throw new ArgumentException("Enumerated item is invalid");
        }

        return this.sourceHistory.IndexOf(sourceItem);
    }

    public void Insert(int index, IChatMessage chatMessage)
    {
        var sourceItem = ((ChatMessage)chatMessage).SourceChatMessageContent2;

        if ( sourceItem is null )
        {
            throw new ArgumentException("Enumerated item is invalid");
        }

        this.sourceHistory.Insert(index, sourceItem);
    }

    public void RemoveAt(int index)
    {
        var privateItem = this[index];
        this.sourceHistory.RemoveAt(index);
//        this.privateToPublicMap.Remove(privateItem.SourceChatMessageContent2);
    }

    public int Count
    {
        get
        {
            return this.sourceHistory.Count;
        }
    }

    public bool IsReadOnly
    {
        get
        {
            return ((System.Collections.Generic.ICollection<IChatMessage>)this.sourceHistory).IsReadOnly;
        }
    }

    public void Add(IChatMessage chatMessage)
    {
        Insert(this.Count, chatMessage);
    }

    public void Clear()
    {
        this.sourceHistory.Clear();
//        this.privateToPublicMap.Clear();
    }

    public bool Contains(IChatMessage chatMessage)
    {
        var sourceItem = ((ChatMessage)chatMessage).SourceChatMessageContent2;

        if ( sourceItem is null )
        {
            throw new ArgumentException("Enumerated item is invalid");
        }

        return this.sourceHistory.Contains(sourceItem);
    }

    public void CopyTo(IChatMessage[] array, int arrayIndex)
    {
        if ( arrayIndex >= 0 )
        {
            if ( arrayIndex >= array.Length ||
                 (arrayIndex + Count > array.Length ) )
            {
                throw new ArgumentOutOfRangeException("The size of the destination array is smaller than the source array");
            }

            int currentIndex = 0;

            foreach ( var sourceChatMessage in this.sourceHistory )
            {
                array[currentIndex++] = sourceChatMessage;
            }
        }
        else
        {
            throw new ArgumentOutOfRangeException("The specified index is out of range");
        }
    }

    public bool Remove(IChatMessage chatMessage)
    {
        var sourceItem = ((ChatMessage)chatMessage).SourceChatMessageContent2;

        if ( sourceItem is null )
        {
            throw new ArgumentException("Enumerated item is invalid");
        }

        var index = this.sourceHistory.IndexOf(chatMessage);

        bool existed = index > -1;

        if ( existed )
        {
            this.RemoveAt(index);
        }

        return existed;
    }

    public IEnumerator<IChatMessage> GetEnumerator()
    {
        return this.sourceHistory.GetEnumerator();
    }

    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
    {
        return ((IEnumerable<IChatMessage>) this).GetEnumerator();
    }

    public IChatMessage? GetPublicItem(IChatMessage? privateObject)
    {
        return privateObject;
        /*
        var privateItem = privateObject;

        ChatMessage? publicItem;

        if ( ! this.privateToPublicMap.TryGetValue(privateItem, out publicItem) )
        {
            publicItem = new ChatMessage(privateItem);
            this.privateToPublicMap.Add(privateItem, publicItem);
        }

        if ( publicItem is null )
        {
            throw new ArgumentException("A null value was present in the collection");
        }

        return publicItem;
*/
/*
    }

    public void Reset()
    {
        var systemMessage = this.sourceHistory.Count > 0 ?
            GetPublicItem(this.sourceHistory[0]) :
            null;

        Clear();

        if ( systemMessage is not null )
        {
            Add(systemMessage);
        }
    }

    public void AddMessage(SenderRole role, string prompt, IReadOnlyDictionary<string,object?>? messageProperties)
    {
        var newMessage = new ChatMessage(role, prompt, messageProperties);

        Add(newMessage);
    }

    internal IList<IChatMessage> SourceHistory
    {
        get
        {
            return this.sourceHistory;
        }
    }

    private System.Collections.Generic.IList<IChatMessage> sourceHistory;
}
*/

