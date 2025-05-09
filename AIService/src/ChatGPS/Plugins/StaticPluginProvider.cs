//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public class StaticPluginProvider : PluginProvider
{
    internal StaticPluginProvider(Type kernelPluginType) : this(kernelPluginType.Name, kernelPluginType) {}

    internal StaticPluginProvider(string name, Type kernelPluginType) : base(name)
    {
        this.NativeType = kernelPluginType;
        this.nativeInstance = null;
    }

    internal override object GetNativeInstance(object[]? parameters = null)
    {
        if ( this.nativeInstance is null )
        {
            var kernelPlugin = Activator.CreateInstance( this.NativeType, parameters );

            if ( kernelPlugin is null )
            {
                throw new InvalidOperationException($"The plugin provider type '{this.NativeType.FullName}' could not be instantiated");
            }
            this.nativeInstance = kernelPlugin;
        }

        return this.nativeInstance;
    }

    private Type NativeType { get; set; }

    private object? nativeInstance;
}
