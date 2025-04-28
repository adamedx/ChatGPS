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

public abstract class Plugin
{
    static Plugin()
    {
        Plugin.plugins = new Dictionary<string, Plugin>(StringComparer.OrdinalIgnoreCase);

        #pragma warning disable SKEXP0050
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.FileIOPlugin)));
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.MathPlugin)));
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.TextPlugin)));
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Core.HttpPlugin)));
        Plugin.RegisterPlugin(new WebSearchPlugin(WebSearchPlugin.SearchSource.Bing));
        Plugin.RegisterPlugin(new WebSearchPlugin(WebSearchPlugin.SearchSource.Google));
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Web.WebFileDownloadPlugin)));
        Plugin.RegisterPlugin(new StaticPlugin(typeof(Microsoft.SemanticKernel.Plugins.Web.SearchUrlPlugin)));
        #pragma warning restore SKEXP0050
    }

    protected Plugin(string name)
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

    internal static object? RegisterPlugin(Plugin plugin, object[]? instanceParameters = null, bool getNativeInstance = false)
    {
        object? result = null;

        if ( Plugin.plugins.ContainsKey(plugin.Name) )
        {
            throw new ArgumentException($"The specified plugin '{plugin.Name}' already exists");
        }

        if ( getNativeInstance )
        {
            result = plugin.GetNativeInstance( instanceParameters );
        }

        Plugin.plugins.Add(plugin.Name, plugin);

        return result;
    }

    public static object? NewPlugin(Plugin plugin, object[]? instanceParameters = null)
    {
        return RegisterPlugin(plugin, instanceParameters, true);
    }

    public static IEnumerable<Plugin> GetPlugins()
    {
        return Plugin.plugins.Values;
    }

    public static Plugin GetPluginByName(string name)
    {
        return Plugin.plugins[name];
    }

    public string Name { get; private set; }

    internal virtual string[]? GetPluginDataJson()
    {
        return null;
    }

    private static Dictionary<string, Plugin> plugins;

}
