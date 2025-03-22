//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginTable
{
    internal PluginTable(Kernel kernel, Dictionary<string,PluginInfo>? pluginMap = null)
    {
        this.plugins = pluginMap is not null ? pluginMap : new Dictionary<string,PluginInfo>(StringComparer.OrdinalIgnoreCase);
        this.kernel = kernel;
    }

    public PluginTable(Dictionary<string,PluginInfo>? pluginMap = null)
    {

        this.plugins = pluginMap is not null ? pluginMap : new Dictionary<string,PluginInfo>(StringComparer.OrdinalIgnoreCase);
        this.kernel = null;
    }

    public PluginInfo GetPluginInfo(string name)
    {
        return this.plugins[name];
    }

    public void AddPlugin(string name, object[]? parameters)
    {
        var plugin = Plugin.GetPluginByName(name);
        var pluginInfo = new PluginInfo(name, plugin.GetType(), parameters);

        if ( this.kernel is not null )
        {
            var nativePlugin = plugin.GetNativeInstance(parameters);
            var kernelPlugin = this.kernel.Plugins.AddFromObject(nativePlugin);
            pluginInfo.BindPlugin(kernelPlugin);
        }

        this.plugins.Add(name, pluginInfo);
    }

    public void RemovePlugin(string name)
    {
        var pluginInfo = this.plugins[name];

        if ( this.kernel is not null )
        {
            if ( pluginInfo.KernelPlugin is null )
            {
                throw new InvalidOperationException($"The specified plugin {name} was not bound to a native plugin");
            }

            this.kernel.Plugins.Remove(pluginInfo.KernelPlugin);
        }

        this.plugins.Remove(name);
    }

    public IEnumerable<PluginInfo> Plugins
    {
        get
        {
            return this.plugins.Values;
        }
    }

    public Dictionary<string,PluginInfo> ToPluginMap()
    {
        var pluginMap = new Dictionary<string,PluginInfo>();

        foreach ( var plugin in this.plugins.Values )
        {
            pluginMap.Add(plugin.Name, plugin);
        }

        return pluginMap;
    }

    internal Dictionary<string,PluginInfo> plugins { get; set; }
    Kernel? kernel;
}
