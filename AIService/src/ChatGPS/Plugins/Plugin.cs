//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class Plugin
{
    public Plugin() {}

    public Plugin(string name, PluginProvider provider, object[]? parameters)
    {
        this.Name = name;
        this.Parameters = PluginProvider.TranslateSerializedParameters(parameters);
        this.Id = Guid.NewGuid();
        this.PluginDataJson = provider.GetProviderDataJson();
        this.PluginType = provider.GetType().FullName;
    }

    // Should be BindKernelPlugin
    internal void BindPlugin(KernelPlugin kernelPlugin)
    {
        if ( this.kernelPlugin is not null )
        {
            throw new InvalidOperationException("The object is already bound to an existing kernel plugin");
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
    public string[]? PluginDataJson { get; set; }
    public string? PluginType { get; set ; }

    private KernelPlugin? kernelPlugin;
}
