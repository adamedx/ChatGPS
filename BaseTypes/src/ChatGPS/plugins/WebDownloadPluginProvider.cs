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

namespace Modulus.ChatGPS.Plugins;

public class WebDownloadPluginProvider : PluginProvider
{
    internal WebDownloadPluginProvider() : base("WebDownloadPlugin")
    {
        this.Description = "Enables the ability to download internet content to the local file system";
        AddPluginParameter("allowedFolders", "Allosed destination directories for downloaded content", true);
        AddPluginParameter("allowedDomains", "Allowed domains of hosts from which to download content", true);
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null, IShellContext? context = null)
    {
        if ( parameters is null || parameters.Count < 2 )
        {
            throw new ArgumentException("Invalid parameters specified -- the allowedFolders and allowedDomains parameters must be specified");
        }

        if ( this.nativeInstance is null )
        {
            this.nativeInstance = null;
            throw new NotImplementedException("The WebDownload Plugin Provider is not yet implemented");
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}
