//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

namespace Modulus.ChatGPS.Plugins;

public sealed class BravePluginProvider : PluginProvider
{
    public BravePluginProvider() : base("BraveSearch", "Enables access to search the web using Brave.")
    {
        AddPluginParameter("apiKey", "Key credential for accessing the Brave Search API.", true, true);
        AddPluginParameter("apiUri", "URI for the API if there is no default URI or if a specific URI is needed.");
    }

    public override object GetNativeInstance(Dictionary<string, PluginParameterValue>? parameters = null, IShellContext? context = null)
    {
        if ( parameters is null )
        {
            throw new ArgumentException("The Brave plugin requires an API key.");
        }

        if ( this.nativeInstance is null )
        {
            var apiKey = (string?) GetPluginParameter("apiKey", parameters);
            var apiUri = (string?) GetPluginParameter("apiUri", parameters);

            this.nativeInstance = new BraveNativePlugin(apiKey ?? string.Empty, apiUri);
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}
