//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public interface IPluginTable
{
    void AddPlugin(string name, object[]? parameters = null);
    void RemovePlugin(string name);
    bool TryGetPluginInfo(string name, out PluginInfo? pluginInfo);
    IEnumerable<PluginInfo> Plugins {get;}
}
