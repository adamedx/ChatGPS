//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginInfo
{
    public PluginInfo(string name, Plugin plugin, object[]? parameters)
    {
        if ( ! plugin.GetType().IsSubclassOf(typeof(Plugin)) )
        {
            throw new ArgumentException($"The specified type {plugin.GetType().FullName} of the specified plugin is not valid because it does not inherit from the type {typeof(Plugin).FullName}");
        }

        this.Name = name;
        this.Parameters = parameters;
    }

    internal void BindPlugin(KernelPlugin kernelPlugin)
    {
        if ( this.kernelPlugin is not null )
        {
            throw new InvalidOperationException("The object is already bound to an existing plugin");
        }

        this.kernelPlugin = kernelPlugin;
    }

    internal KernelPlugin? GetKernelPlugin()
    {
        return this.kernelPlugin;
    }

    public string Name { get; set; }
    public object[]? Parameters { get; set; }
    public Guid Id { get; set; }

    private KernelPlugin? kernelPlugin;
}
