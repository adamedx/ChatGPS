//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Text.Json;
using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Utilities;

namespace Modulus.ChatGPS.Plugins;

public abstract class PluginProvider
{
    static PluginProvider()
    {
        PluginProvider.providers = new Dictionary<string, PluginProvider>(StringComparer.OrdinalIgnoreCase);

        #pragma warning disable SKEXP0050
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Core.FileIOPlugin),
                                                                 "Enables read and write access to the local file system."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Core.MathPlugin),
                                                                 "Uses the local computer to computer the value of mathematical expressions efficiently."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Core.TextPlugin),
                                                                 "Allows the local computer to perform string manipulations."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Core.HttpPlugin),
                                                                 "Enables the local computer to access local and remote resources via http protocol requests."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Core.TimePlugin),
                                                                 "Uses the local computer to obtain the current time."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Web.WebFileDownloadPlugin),
                                                                 "Enables access to web content by downloading it to the local computer."));
        PluginProvider.RegisterProvider(new StaticPluginProvider(typeof(Microsoft.SemanticKernel.Plugins.Web.SearchUrlPlugin),
                                                                 "Computes the search url for popular websites."));
        PluginProvider.RegisterProvider(new WebSearchPluginProvider(WebSearchPluginProvider.SearchSource.Bing, "Bing"));
        PluginProvider.RegisterProvider(new WebSearchPluginProvider(WebSearchPluginProvider.SearchSource.Google, "Google"));
        #pragma warning restore SKEXP0050
    }

    public IEnumerable<PluginParameter> Parameters
    {
        get
        {
            return this.parameterSpec.Values;
        }
    }

    protected PluginProvider(string name, string? description = null)
    {
        this.parameterSpec = new Dictionary<string, PluginParameter>();

        this.Name = name;
        this.Description = description ?? "Allows local operations to be invoked by instructions from a language model.";
    }

    internal abstract object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters);

    internal virtual void InitializeInstanceFromData(string[] jsonData) { }

    internal static object? RegisterProvider(PluginProvider provider, Dictionary<string,PluginParameterValue>? instanceParameters = null, bool getNativeInstance = false)
    {
        object? result = null;

        if ( PluginProvider.providers.ContainsKey(provider.Name) )
        {
            throw new ArgumentException($"The specified plugin provider '{provider.Name}' already exists");
        }

        if ( getNativeInstance )
        {
            result = provider.GetNativeInstance( instanceParameters );
        }

        PluginProvider.providers.Add(provider.Name, provider);

        return result;
    }

    public static object? NewProvider(PluginProvider provider, Dictionary<string,PluginParameterValue>? instanceParameters = null)
    {
        return RegisterProvider(provider, instanceParameters, true);
    }

    public static IEnumerable<PluginProvider> GetProviders()
    {
        return PluginProvider.providers.Values;
    }

    public static PluginProvider GetProviderByName(string name)
    {
        return PluginProvider.providers[name];
    }

    public string Name { get; private set; }
    public string Description { get; protected set; }

    internal virtual string[]? GetProviderDataJson()
    {
        return null;
    }

    protected object? GetPluginParameter(string name, Dictionary<string,PluginParameterValue>? parameters)
    {
        PluginParameter? parameter = null;

        if ( parameters is null )
        {
            throw new InvalidOperationException($"The parameter {name} cannot be read for the plugin because the parameters have not been initialized.");
        }

        try
        {
            parameter = this.parameterSpec[name];
        }
        catch ( KeyNotFoundException e )
        {
            throw new KeyNotFoundException($"The parameter '{name}' is not defined for this plugin", e);
        }

        object? parameterData = null;

        var parameterValue = parameters.ContainsKey(name) ? parameters[name] : null;

        if ( parameterValue is not null )
        {
            try
            {
                parameterData = parameterValue.GetValue();
            }
            catch (Exception e)
            {
                if ( parameterValue.Encrypted )
                {
                    throw new ArgumentException($"The encrypted parameter '{name}' for the plugin '{this.Name}' could not be accessed, possibly due to a decryption failure. Ensure that the parameter value was correctly encrypted and that encryption support is available for the OS platform and correctly configured.", e);
                }
                else
                {
                    throw;
                }
            }
        }

        if ( parameter.Required && parameterData is null )
        {
            throw new ArgumentException($"The required parameter '{name}' was not specified for the plugin '{this.Name}'");
        }

        return parameterData;
    }

    protected void AddPluginParameter(string name, string description, bool required = false, bool encrypted = false)
    {
        var parameter = new PluginParameter(name, description, required, encrypted);

        this.parameterSpec.Add(name, parameter);
    }

    private static Dictionary<string, PluginProvider> providers;

    private Dictionary<string, PluginParameter> parameterSpec;
}
