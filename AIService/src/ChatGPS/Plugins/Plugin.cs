//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
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
        #pragma warning restore SKEXP0050
    }

    protected Plugin(string name)
    {
        this.Name = name;
    }

    internal abstract object GetNativeInstance(string[]? parameters = null);

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

    private static Dictionary<string, Plugin> plugins;

}
