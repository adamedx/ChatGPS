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

using System.Collections.Generic;
using System.Text.Json;

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginTable : IPluginTable
{
    public PluginTable(Kernel kernel, IEnumerable<Plugin>? plugins = null)
    {
        this.plugins = plugins is not null ? PluginTable.ToPluginMap(plugins) : new Dictionary<string,Plugin>(StringComparer.OrdinalIgnoreCase);

        SynchronizePlugins(plugins);
        this.kernel = kernel;
    }

    public PluginTable(IEnumerable<Plugin>? plugins = null)
    {
        this.plugins = plugins is not null ? PluginTable.ToPluginMap(plugins) : new Dictionary<string,Plugin>(StringComparer.OrdinalIgnoreCase);
        this.kernel = null;
    }

    public bool TryGetPlugin(string name, out Plugin? plugin)
    {
        var hasPlugin = this.plugins.ContainsKey(name);

        if ( hasPlugin )
        {
            plugin = this.plugins[name];
        }
        else
        {
            plugin = null;
        }

        return hasPlugin;
    }

    public void AddPlugin(string name, Dictionary<string,PluginParameterValue>? parameters)
    {
        var provider = PluginProvider.GetProviderByName(name);

        var plugin = new Plugin(provider.Name, provider, parameters);

        if ( this.kernel is not null )
        {
            var nativePlugin = provider.GetNativeInstance(plugin.Parameters);
            var kernelPlugin = this.kernel.Plugins.AddFromObject(nativePlugin);
            plugin.BindKernelPlugin(kernelPlugin);
        }

        this.plugins.Add(provider.Name, plugin);
    }

    public void RemovePlugin(string name)
    {
        var plugin = this.plugins[name];

        if ( this.kernel is not null )
        {
            var kernelPlugin = plugin.GetKernelPlugin();

            if ( kernelPlugin is null )
            {
                throw new InvalidOperationException($"The specified plugin {name} was not bound to a native plugin");
            }

            this.kernel.Plugins.Remove(kernelPlugin);
        }

        this.plugins.Remove(name);
    }

    public IEnumerable<Plugin> Plugins
    {
        get
        {
            return this.plugins.Values;
        }
    }

    public static void SynchronizePlugins(IPluginTable pluginTable, IEnumerable<Plugin>? latestPlugins)
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
            foreach ( var latestPlugin in latestPlugins )
            {
                Plugin? foundPlugin;

                if ( latestPlugin.Name is null )
                {
                    throw new InvalidOperationException("The plugin information is null");
                }

                if ( ! pluginTable.TryGetPlugin(latestPlugin.Name, out foundPlugin) )
                {
                    if ( latestPlugin.PluginDataJson is not null )
                    {
                        if ( latestPlugin.PluginType is null )
                        {
                            throw new ArgumentException($"The specified plugin '{latestPlugin.Name}' did not include a type name for the plugin.");
                        }

                        var pluginIsRegistered = false;

                        try
                        {
                            PluginProvider.GetProviderByName(latestPlugin.Name);
                            pluginIsRegistered = true;
                        }
                        catch
                        {
                        }

                        if ( ! pluginIsRegistered )
                        {
                            var pluginType = Type.GetType(latestPlugin.PluginType);

                            if ( pluginType is null )
                            {
                                throw new ArgumentException($"The specified plugin provider type '{latestPlugin.PluginType}' is not a valid type");
                            }

                            var constructorArguments = new string[] { latestPlugin.Name };
                            var customProvider = (PluginProvider?) Activator.CreateInstance( pluginType, constructorArguments );

                            if ( customProvider is null )
                            {
                                throw new InvalidOperationException($"The attempt to create a new instance of the plugin provider type '{latestPlugin.PluginType}' failed.");
                            }

                            customProvider.InitializeInstanceFromData(latestPlugin.PluginDataJson);

                            PluginProvider.RegisterProvider(customProvider);
                        }
                    }

                    pluginTable.AddPlugin(latestPlugin.Name, latestPlugin.Parameters);
                }
            }

        }
    }

    private static Dictionary<string,Plugin> ToPluginMap(IEnumerable<Plugin> plugins)
    {
        var pluginMap = new Dictionary<string,Plugin>(StringComparer.OrdinalIgnoreCase);

        foreach ( var plugin in plugins )
        {
            if ( plugin.Name is null )
            {
                throw new InvalidOperationException("The plugin information is null");
            }

            pluginMap.Add(plugin.Name, plugin);
        }

        return pluginMap;
    }

    private void SynchronizePlugins(IEnumerable<Plugin>? latestPlugins)
    {
        PluginTable.SynchronizePlugins(this, latestPlugins);
    }

    private Kernel? kernel;
    private Dictionary<string,Plugin> plugins;
}

