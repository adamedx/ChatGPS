//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginTable : IPluginTable
{
    internal PluginTable(Kernel kernel, IEnumerable<PluginInfo>? plugins = null)
    {
        this.plugins = plugins is not null ? PluginTable.ToPluginMap(plugins) : new Dictionary<string,PluginInfo>(StringComparer.OrdinalIgnoreCase);

        SynchronizePlugins(plugins);

        this.kernel = kernel;
    }

    public PluginTable(IEnumerable<PluginInfo>? plugins = null)
    {
        this.plugins = plugins is not null ? PluginTable.ToPluginMap(plugins) : new Dictionary<string,PluginInfo>(StringComparer.OrdinalIgnoreCase);
        this.kernel = null;
    }

    public bool TryGetPluginInfo(string name, out PluginInfo? pluginInfo)
    {
        var hasPlugin = this.plugins.ContainsKey(name);

        if ( hasPlugin )
        {
            pluginInfo = this.plugins[name];
        }
        else
        {
            pluginInfo = null;
        }

        return hasPlugin;
    }

    public void AddPlugin(string name, object[]? parameters, bool noProxy = false)
    {
        var plugin = Plugin.GetPluginByName(name);

        if ( noProxy && plugin.NoProxy )
        {
            throw new InvalidOperationException("This plugin is not compatible with proxy mode; create a session with proxy mode disabled and retry the operation with that session");
        }

        var pluginInfo = new PluginInfo(name, plugin, parameters);

        if ( this.kernel is not null )
        {
            var nativePlugin = plugin.GetNativeInstance(pluginInfo.Parameters);
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
            var kernelPlugin = pluginInfo.GetKernelPlugin();

            if ( kernelPlugin is null )
            {
                throw new InvalidOperationException($"The specified plugin {name} was not bound to a native plugin");
            }

            this.kernel.Plugins.Remove(kernelPlugin);
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

    public static void SynchronizePlugins(IPluginTable pluginTable, IEnumerable<PluginInfo>? latestPlugins)
    {
        if ( latestPlugins is not null )
        {
            var latestPluginMap = ToPluginMap(latestPlugins);

            // Remove any plugins that have been removed from the latest list or
            // are out of date
            foreach ( var currentPlugin in pluginTable.Plugins )
            {
                if ( currentPlugin.Name is null )
                {
                    throw new InvalidOperationException("The plugin information is null");
                }

                if ( ! latestPluginMap.ContainsKey(currentPlugin.Name) ||
                     ( latestPluginMap[currentPlugin.Name].Id != currentPlugin.Id ) )
                {
                    pluginTable.RemovePlugin(currentPlugin.Name);
                }
            }

            // Add plugins from the latest list that aren't present in the current
            foreach ( var latestPluginInfo in latestPlugins )
            {
                PluginInfo? foundPlugin;

                if ( latestPluginInfo.Name is null )
                {
                    throw new InvalidOperationException("The plugin information is null");
                }

                if ( ! pluginTable.TryGetPluginInfo(latestPluginInfo.Name, out foundPlugin) )
                {
                    pluginTable.AddPlugin(latestPluginInfo.Name, latestPluginInfo.Parameters);
                }
            }

        }
    }

    internal Dictionary<string,PluginInfo> plugins { get; set; }

    private static Dictionary<string,PluginInfo> ToPluginMap(IEnumerable<PluginInfo> plugins)
    {
        var pluginMap = new Dictionary<string,PluginInfo>(StringComparer.OrdinalIgnoreCase);

        foreach ( var pluginInfo in plugins )
        {
            if ( pluginInfo.Name is null )
            {
                throw new InvalidOperationException("The plugin information is null");
            }

            pluginMap.Add(pluginInfo.Name, pluginInfo);
        }

        return pluginMap;
    }

    private void SynchronizePlugins(IEnumerable<PluginInfo>? latestPlugins)
    {
        PluginTable.SynchronizePlugins(this, latestPlugins);
    }

    private Kernel? kernel;
}
