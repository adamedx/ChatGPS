//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Plugins.Web;
using Microsoft.SemanticKernel.Plugins.Web.Bing;
using Microsoft.SemanticKernel.Plugins.Web.Google;

namespace Modulus.ChatGPS.Plugins;

public class WebSearchPlugin : PluginProvider
{
    internal enum SearchSource
    {
        Bing,
        Google
    }

    internal WebSearchPlugin(SearchSource source) : base(source.ToString())
    {
        this.source = source;
    }

    internal override object GetNativeInstance(object[]? parameters = null)
    {
        if ( parameters is null || parameters.Length < 1 )
        {
            throw new ArgumentException("Invalid parameters specified -- at least one parameter must be specified, the first must be the API key, the second is optional and may be an API URI");
        }

        if ( this.nativeInstance is null )
        {
            #pragma warning disable SKEXP0050

            var apiKey = (string) parameters[0];
            IWebSearchEngineConnector connector;

            switch ( source )
            {
            case SearchSource.Bing:
                var apiUri = parameters.Length > 1 ? new Uri((string) parameters[1]) : null;
                connector = new BingConnector(apiKey, apiUri);
                break;
            case SearchSource.Google:
                if (  parameters.Length < 2 )
                {
                    throw new ArgumentException("Invalid parameters specified -- the first must be the API key, the second parameter must be the search engine Id");
                }

                var searchEngineId = (string) parameters[1];
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
