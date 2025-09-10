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

using System.Text;

namespace Modulus.ChatGPS.Utilities;

internal class TailReader
{
    internal TailReader(int tailCount)
    {
        this.buffer = new CircularBuffer<string>(tailCount);
    }

    internal string ReadTail(string textFilePath)
    {
        this.buffer.Clear();

        string? line;

        using ( var reader = new StreamReader(textFilePath) )
        {
            while ( ( line = reader.ReadLine() ) is not null )
            {
                this.buffer.Add(line);
            }
        }

        var capacity = 0;

        for ( int i = 0; i < buffer.Count; i++ )
        {
            capacity += this.buffer.Get(i).Length;
        }

        var builder = new StringBuilder(capacity);

        for ( int j = 0; j < buffer.Count; j++ )
        {
            builder.Append(this.buffer.Get(j));
        }

        return builder.ToString();
    }

    CircularBuffer<string> buffer;
}
