//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public class StaticPlugin : Plugin
{
    internal StaticPlugin(Type kernelPluginType) : this(kernelPluginType.Name, kernelPluginType) {}

    internal StaticPlugin(string name, Type kernelPluginType) : base(name)
    {
        this.NativeType = kernelPluginType;
        this.nativeInstance = null;
    }

    internal override object GetNativeInstance(string[]? parameters = null)
    {
        if ( this.nativeInstance is null )
        {
            var kernelPlugin = Activator.CreateInstance( this.NativeType, parameters );

            if ( kernelPlugin is null )
            {
                throw new InvalidOperationException($"The plugin type '{this.NativeType.FullName}' could not be instantiated");
            }
            this.nativeInstance = kernelPlugin;
        }

        return this.nativeInstance;
    }

    private Type NativeType { get; set; }

    private object? nativeInstance;
}
