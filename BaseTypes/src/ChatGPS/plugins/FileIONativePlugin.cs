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

using System.ComponentModel;
using System.IO;
using System.Text;

namespace Modulus.ChatGPS.Plugins;

[Description("Enables read and write access to the local file system.")]
public sealed class FileIONativePlugin
{
    [Description("Read a file")]
    public async Task<string> read_async([Description("Source file")] string path)
    {
        using var reader = new StreamReader(path);

        return await reader.ReadToEndAsync().ConfigureAwait(false);
    }

    [Description("Write a file")]
    public async Task write_async([Description("Destination file")] string path, [Description("File content")] string content)
    {
        var bytes = Encoding.UTF8.GetBytes(content);

        using var writer = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None);

        await writer.WriteAsync(bytes).ConfigureAwait(false);
    }
}
