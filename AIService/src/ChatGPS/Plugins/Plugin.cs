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
        Plugin.RegisterPlugin(new WebSearchPlugin(WebSearchPlugin.SearchSource.Bing));
        Plugin.RegisterPlugin(new WebSearchPlugin(WebSearchPlugin.SearchSource.Google));
        Plugin.RegisterPlugin(new PowerShellPlugin());
        #pragma warning restore SKEXP0050
    }

    protected Plugin(string name, bool noProxy = false)
    {
        this.Name = name;
        this.NoProxy = noProxy;
    }

    internal abstract object GetNativeInstance(object[]? parameters = null);

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


    internal static void RegisterPlugin(Plugin plugin)
    {
        Plugin.plugins.Add(plugin.Name, plugin);
    }

    public static IEnumerable<Plugin> GetPlugins()
    {
        return Plugin.plugins.Values;
    }

    internal static Plugin GetPluginByName(string name)
    {
        return Plugin.plugins[name];
    }

    public string Name { get; private set; }

    public bool NoProxy { get; set; }

    private static Dictionary<string, Plugin> plugins;

}
