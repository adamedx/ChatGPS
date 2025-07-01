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

    public Plugin(string name, PluginProvider provider, Dictionary<string,PluginParameterValue>? parameters)
    {
        this.Name = name;
        this.Parameters = parameters is not null ? new Dictionary<string,PluginParameterValue>(parameters, StringComparer.OrdinalIgnoreCase) : null;
        this.Id = Guid.NewGuid();
        this.PluginDataJson = provider.GetProviderDataJson();
        this.PluginType = provider.GetType().FullName;
    }

    internal void BindKernelPlugin(KernelPlugin kernelPlugin)
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
    public Dictionary<string,PluginParameterValue>? Parameters { get; set; }
    public Guid? Id { get; set; }
    public string[]? PluginDataJson { get; set; }
    public string? PluginType { get; set ; }

    private KernelPlugin? kernelPlugin;
}
