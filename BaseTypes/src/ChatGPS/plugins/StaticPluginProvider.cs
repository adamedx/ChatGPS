//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Plugins;

public class StaticPluginProvider : PluginProvider
{
    internal StaticPluginProvider(Type kernelPluginType, string? description) : this(kernelPluginType.Name, kernelPluginType, description) {}

    internal StaticPluginProvider(string name, Type kernelPluginType, string? description) : base(name, description)
    {
        this.NativeType = kernelPluginType;
        this.nativeInstance = null;
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null)
    {
        if ( this.nativeInstance is null )
        {
            var nativeParameters = new object?[ parameters?.Count ?? 0 ];

            if ( parameters is not null )
            {
                int parameterIndex = 0;

                foreach ( var parameter in parameters.Values )
                {
                    nativeParameters[parameterIndex++] = parameter.GetDecryptedValue();
                }
            }

            var kernelPlugin = Activator.CreateInstance( this.NativeType, nativeParameters );

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
