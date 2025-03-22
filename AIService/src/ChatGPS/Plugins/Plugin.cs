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
        #pragma warning restore SKEXP0050
    }

    protected Plugin(string name, Type nativeType)
    {
        this.Name = name;
        this.NativeType = nativeType;
        this.nativeInstance = null;
    }

    protected Plugin(Type nativeType)
    {
        this.Name = nativeType.Name;
        this.NativeType = nativeType;
        this.nativeInstance = null;
    }

    internal object GetNativeInstance(object[]? parameters = null)
    {
        if ( this.nativeInstance is null )
        {
            var kernelPlugin = Activator.CreateInstance( this.NativeType );

            if ( kernelPlugin is null )
            {
                throw new InvalidOperationException($"The plugin type '{this.NativeType.FullName}' could not be instantiated");
            }
            this.nativeInstance = kernelPlugin;
        }

        return this.nativeInstance;
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

    public string Name { get; set; }
    public Type NativeType { get; set; }

    private static Dictionary<string, Plugin> plugins;
    private object? nativeInstance;
}
