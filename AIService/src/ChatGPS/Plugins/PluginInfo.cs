//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PluginInfo
{
    public PluginInfo() {}

    public PluginInfo(string name, Plugin plugin, string[]? parameters)
    {
        this.Name = name;
        this.Parameters = parameters;
        this.Id = Guid.NewGuid();
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

    public string? Name { get; set; }
    public string[]? Parameters { get; set; }
    public Guid? Id { get; set; }

    private KernelPlugin? kernelPlugin;
}
