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
using Microsoft.SemanticKernel.Plugins.Web;
using Microsoft.SemanticKernel.Plugins.Web.Bing;
using Microsoft.SemanticKernel.Plugins.Web.Google;

namespace Modulus.ChatGPS.Plugins;

public class WebSearchPluginProvider : PluginProvider
{
    internal enum SearchSource
    {
        Bing,
        Google
    }

    internal WebSearchPluginProvider(SearchSource source, string sourceDescription) : base(source.ToString())
    {
        this.source = source;
        this.Description = $"Enables access to search the web using the following search engine source: {sourceDescription}";
        AddPluginParameter("apiKey", "Key credential for accessing the search engine's API", true, true);
        AddPluginParameter("apiUri", "URI for the API if there is no default URI or if a specific URI is needed");
        AddPluginParameter("searchEngineId", "Id for the search engine instance required for search engine scenarios", false, false);
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null)
    {
        if ( parameters is null || parameters.Count < 1 )
        {
            throw new ArgumentException("Invalid parameters specified -- at least one parameter must be specified, the first must be the API key, the second is optional and may be an API URI");
        }

        if ( this.nativeInstance is null )
        {
            #pragma warning disable SKEXP0050

            if ( parameters is null )
            {
                throw new ArgumentException("Invalid parameters specified -- at least one parameter must be specified, the first must be the API key, the second is optional and may be an API URI");
            }

            var apiKey = (string?) GetPluginParameter("apiKey", parameters) ?? "";

            IWebSearchEngineConnector connector;

            switch ( source )
            {
            case SearchSource.Bing:
                var apiUriData = (string?) GetPluginParameter("apiUri", parameters);

                var apiUri = apiUriData is not null ? new Uri(apiUriData ?? "" ) : null;

                connector = new BingConnector(apiKey, apiUri);
                break;
            case SearchSource.Google:
                if (  parameters.Count < 2 )
                {
                    throw new ArgumentException("Invalid parameters specified -- the first must be the API key, the second parameter must be the search engine Id");
                }

                var searchEngineId = (string?) GetPluginParameter("searchEngineId", parameters) ?? "";
                connector = new GoogleConnector(apiKey, searchEngineId);
                break;
            default:
                throw new ArgumentException($"Unsupported search source 'SearchSource'");
            }

            this.nativeInstance = new WebSearchEnginePlugin(connector);

            #pragma warning restore SKEXP0050
        }

        return this.nativeInstance;
    }

    SearchSource source;
    private object? nativeInstance;
}

