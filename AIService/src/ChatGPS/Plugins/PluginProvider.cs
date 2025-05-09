//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Text.Json;
using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public abstract class PluginProvider
{
    static PluginProvider()
    {
        PluginProvider.providers = new Dictionary<string, PluginProvider>(StringComparer.OrdinalIgnoreCase);

        #pragma warning disable SKEXP0050
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.FileIOPlugin)));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.MathPlugin)));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.TextPlugin)));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.HttpPlugin)));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.TimePlugin)));
        PluginProvider.RegisterProvider(new WebSearchPlugin(WebSearchPlugin.SearchSource.Bing));
        PluginProvider.RegisterProvider(new WebSearchPlugin(WebSearchPlugin.SearchSource.Google));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Web.WebFileDownloadPlugin)));
        PluginProvider.RegisterProvider(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Web.SearchUrlPlugin)));
        #pragma warning restore SKEXP0050
    }

    protected PluginProvider(string name)
    {
        this.Name = name;
    }

    internal abstract object GetNativeInstance(object[]? parameters = null);

    internal virtual void InitializeInstanceFromData(string[] jsonData) { }

    internal static object[]? TranslateSerializedParameters(object[]? parameters)
    {
        var result = parameters;

        if ( parameters is not null && parameters.Length > 0 )
        {
            bool translated = false;

            var newParameters = new object[parameters.Length];

            for ( var parameterIndex = 0; parameterIndex < parameters.Length; parameterIndex++ )
            {
                var parameter = parameters[parameterIndex];

                if ( parameter is JsonElement )
                {
                    var jsonElement = (JsonElement) parameter;

                    newParameters[parameterIndex] = jsonElement.ToString();

                    translated = true;
                }
                else
                {
                    newParameters[parameterIndex] = parameter;
                }
            }

            if ( translated )
            {
                result = newParameters;
            }
        }

        return result;
    }

    internal static object? RegisterProvider(PluginProvider provider, object[]? instanceParameters = null, bool getNativeInstance = false)
    {
        object? result = null;

        if ( PluginProvider.providers.ContainsKey(provider.Name) )
        {
            throw new ArgumentException($"The specified plugin provider '{provider.Name}' already exists");
        }

        if ( getNativeInstance )
        {
            result = provider.GetNativeInstance( instanceParameters );
        }

        PluginProvider.providers.Add(provider.Name, provider);

        return result;
    }

    public static object? NewProvider(PluginProvider provider, object[]? instanceParameters = null)
    {
        return RegisterProvider(provider, instanceParameters, true);
    }

    public static IEnumerable<PluginProvider> GetProviders()
    {
        return PluginProvider.providers.Values;
    }

    public static PluginProvider GetProviderByName(string name)
    {
        return PluginProvider.providers[name];
    }

    public string Name { get; private set; }

    internal virtual string[]? GetProviderDataJson()
    {
        return null;
    }

    private static Dictionary<string, PluginProvider> providers;

}
