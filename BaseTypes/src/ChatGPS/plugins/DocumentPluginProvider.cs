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

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Plugins.Document;
using Microsoft.SemanticKernel.Plugins.Document.FileSystem;
using Microsoft.SemanticKernel.Plugins.Document.OpenXml;

namespace Modulus.ChatGPS.Plugins;

public class DocumentPluginProvider : PluginProvider
{
    internal DocumentPluginProvider() : base("DocumentPlugin")
    {
        this.Description = "Enables the ability to read the contents of Microsoft Word documents in the local file system";
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null)
    {
        if ( parameters is not null && parameters.Count > 0 )
        {
            throw new ArgumentException($"This parameter does not accept parameters, but {parameters.Count} parameters were specified");
        }

        if ( this.nativeInstance is null )
        {
            #pragma warning disable SKEXP0050

            var wordConnector = new WordDocumentConnector();
            var localFileSystemConnector = new LocalFileSystemConnector();

            this.nativeInstance = new DocumentPlugin(wordConnector, localFileSystemConnector);

            #pragma warning restore SKEXP0050
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}

