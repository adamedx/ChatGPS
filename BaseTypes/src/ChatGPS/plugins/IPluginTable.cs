//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;

namespace Modulus.ChatGPS.Plugins;

public interface IPluginTable
{
    void AddPlugin(string name, Dictionary<string,PluginParameterValue>? parameters = null);
    void RemovePlugin(string name);
    bool TryGetPlugin(string name, out Plugin? plugin);
    IEnumerable<Plugin> Plugins {get;}
}
