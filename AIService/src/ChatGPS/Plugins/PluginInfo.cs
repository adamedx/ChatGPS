//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginInfo
{
    public PluginInfo(string name, Type pluginType, object[]? parameters)
    {
        if ( ! pluginType.IsSubclassOf(typeof(Plugin)) )
        {
            throw new ArgumentException($"The specified type {pluginType.FullName} is not a valid plugin because it does not inhert from the type {typeof(Plugin).FullName}");
        }

        this.Name = name;
        this.PluginType = pluginType;
        this.Parameters = parameters;
    }

    internal void BindPlugin(KernelPlugin kernelPlugin)
    {
        if ( this.KernelPlugin is not null )
        {
            throw new InvalidOperationException("The object is already bound to an existing plugin");
        }

        this.KernelPlugin = kernelPlugin;
    }

    public string Name { get; set; }
    public Type PluginType { get; private set; }
    public object[]? Parameters { get; private set; }
    internal KernelPlugin? KernelPlugin { get; private set; }
}
