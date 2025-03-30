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

    public PluginInfo(string name, Plugin plugin, object[]? parameters)
    {
        this.Name = name;
        this.Parameters = Plugin.TranslateSerializedParameters(parameters);
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
    public object[]? Parameters { get; set; }
    public Guid? Id { get; set; }

    private KernelPlugin? kernelPlugin;
}
