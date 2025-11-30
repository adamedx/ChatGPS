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

namespace Modulus.ChatGPS.Models;

internal class ChatMessageEnumerator : System.Collections.Generic.IEnumerator<ChatMessage>
{
    public ChatMessageEnumerator(System.Collections.Generic.IEnumerator<Microsoft.Extensions.AI.ChatMessage> sourceEnumerator,
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

    private System.Collections.Generic.IEnumerator<Microsoft.Extensions.AI.ChatMessage> sourceEnumerator;
    private ChatMessageHistory history;
}
