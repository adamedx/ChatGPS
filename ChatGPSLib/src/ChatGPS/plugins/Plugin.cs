//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public abstract class Plugin
{
    static Plugin()
    {
        Plugin.pluginTypes = new Dictionary<string, Type>();
    }

    protected Plugin(string name)
    {
        this.Name = name;
    }

    internal abstract void AddToKernel(Kernel kernel);

    internal static void RegisterPluginType(string name, Type type)
    {
        pluginTypes.Add(name, type);
    }

    internal static Type GetPluginType(string name)
    {
        return pluginTypes[name];
    }

    public string Name { get; private set; }

    private static Dictionary<string, Type> pluginTypes;
}
