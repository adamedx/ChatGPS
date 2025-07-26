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
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;


public class ChatMessageHistory : System.Collections.Generic.IList<ChatMessage>,
    System.Collections.Generic.ICollection<ChatMessage>,
    System.Collections.Generic.IEnumerable<ChatMessage>
{
    public class ChatMessageEnumerator : System.Collections.Generic.IEnumerator<ChatMessage>
    {
        public ChatMessageEnumerator(System.Collections.Generic.IEnumerator<ChatMessageContent> sourceEnumerator,
                                      ChatMessageHistory history)
        {
            this.sourceEnumerator = sourceEnumerator;
            this.history = history;
        }

        public ChatMessage Current
        {
            get
            {
                return GetCurrent();
            }
        }

        object System.Collections.IEnumerator.Current
        {
            get
            {
                return GetCurrent();
            }
        }

        public bool MoveNext()
        {
            return this.sourceEnumerator.MoveNext();
        }

        public void Reset()
        {
            this.sourceEnumerator.Reset();
        }

        public void Dispose()
        {
            this.sourceEnumerator.Dispose();
        }

        private ChatMessage GetCurrent()
        {
            var privateItem = this.sourceEnumerator.Current;
            return history.GetPublicItem(privateItem);
        }

        private System.Collections.Generic.IEnumerator<ChatMessageContent> sourceEnumerator;
        private ChatMessageHistory history;
    }

    public ChatMessageHistory()
    {
        this.sourceHistory = new ChatHistory();
        this.privateToPublicMap = new System.Collections.Generic.Dictionary<ChatMessageContent, ChatMessage>();
    }

    public ChatMessageHistory( ChatHistory sourceHistory )
    {
        this.sourceHistory = sourceHistory;
        this.privateToPublicMap = new System.Collections.Generic.Dictionary<ChatMessageContent, ChatMessage>();
    }

    public ChatMessage this[int index]
    {
        get
        {
            var privateItem = this.sourceHistory[index];

            return GetPublicItem(privateItem);
        }

        set
        {
            var currentIndex = this.sourceHistory.IndexOf(value.SourceChatMessageContent);

            if ( currentIndex != -1 )
            {
                this.sourceHistory[index] = value.SourceChatMessageContent;
                GetPublicItem(value.SourceChatMessageContent);
            }
            else if ( currentIndex != index )
            {
                throw new InvalidOperationException("The key already exists at another location in the collection");
            }
        }
    }

    public int IndexOf(ChatMessage chatMessage)
    {
        return this.sourceHistory.IndexOf(chatMessage.SourceChatMessageContent);
    }

    public void Insert(int index, ChatMessage chatMessage)
    {
        this.sourceHistory.Insert(index, chatMessage.SourceChatMessageContent);
        GetPublicItem(chatMessage.SourceChatMessageContent);
}

    public void RemoveAt(int index)
    {
        var privateItem = this[index];
        this.sourceHistory.RemoveAt(index);
        this.privateToPublicMap.Remove(privateItem.SourceChatMessageContent);
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
            return ((System.Collections.Generic.ICollection<ChatMessageContent>)this.sourceHistory).IsReadOnly;
        }
    }

    public void Add(ChatMessage chatMessage)
    {
        Insert(this.Count, chatMessage);
    }

    public void Clear()
    {
        this.sourceHistory.Clear();
        this.privateToPublicMap.Clear();
    }

    public bool Contains(ChatMessage chatMessage)
    {
        return this.sourceHistory.Contains(chatMessage.SourceChatMessageContent);
    }

    public void CopyTo(ChatMessage[] array, int arrayIndex)
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
                var publicChatMessage = GetPublicItem(sourceChatMessage);
                array[currentIndex++] = publicChatMessage;
            }
        }
        else
        {
            throw new ArgumentOutOfRangeException("The specified index is out of range");
        }
    }

    public bool Remove(ChatMessage chatMessage)
    {
        var index = this.sourceHistory.IndexOf(chatMessage.SourceChatMessageContent);

        bool existed = index > -1;

        if ( existed )
        {
            this.RemoveAt(index);
        }

        return existed;
    }

    public IEnumerator<ChatMessage> GetEnumerator()
    {
        return new ChatMessageEnumerator(((IEnumerable<ChatMessageContent>)this.sourceHistory).GetEnumerator(), this);
    }

    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
    {
        return ((IEnumerable<ChatMessage>) this).GetEnumerator();
    }

    public ChatMessage GetPublicItem(ChatMessageContent privateObject)
    {
        var privateItem = (ChatMessageContent) privateObject;

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
    }

    public void Reset()
    {
        var systemMessage = sourceHistory.Count > 0 ?
            GetPublicItem(sourceHistory[0]) :
            null;

        Clear();

        if ( systemMessage is not null )
        {
            Add(systemMessage);
        }
    }

    internal ChatHistory SourceHistory
    {
        get
        {
            return this.sourceHistory;
        }
    }

    private ChatHistory sourceHistory;
    private System.Collections.Generic.Dictionary<ChatMessageContent, ChatMessage> privateToPublicMap;
}

