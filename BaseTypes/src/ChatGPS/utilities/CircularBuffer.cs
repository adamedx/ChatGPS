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

namespace Modulus.ChatGPS.Utilities;

internal class CircularBuffer<T>
{
    internal CircularBuffer(int size)
    {
        this.items = new T[size];
    }

    internal void Clear()
    {
        this.Count = 0;
        this.isFull = false;
        this.start = 0;
        this.end = 0;
    }

    internal void Add(T item)
    {
        this.items[this.end] = item;

        this.Count += this.isFull ? 0 : 1;
        this.end = ( this.end + 1 ) % this.items.Length;
        this.isFull = this.isFull || this.end == 0;
        this.start = this.isFull ? this.start + 1 % this.items.Length : 0;
    }

    internal T Get(int index)
    {
        if ( ! this.isFull && index >= this.items.Length )
        {
            throw new IndexOutOfRangeException($"The requested index {index} is out of range because the buffer only contains {this.Count} items.");
        }

        return this.items[(this.start + index) % this.items.Length];
    }

    internal int Count { get; private set; }

    internal int Capacity { get => this.items.Length; }

    T[] items;
    int start = 0;
    int end = 0;
    bool isFull = false;
}
