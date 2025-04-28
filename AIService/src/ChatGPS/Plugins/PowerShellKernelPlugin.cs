//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Text.Json;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellKernelPlugin
{
    protected PowerShellKernelPlugin(string pluginName, string pluginDescription, Dictionary<string,PowerShellScriptBlock> scriptBlocks)
    {
        this.ScriptBlocks = scriptBlocks;
        this.PluginName = pluginName;
        this.PluginDescription = pluginDescription;
    }

    public Dictionary<string,PowerShellScriptBlock> ScriptBlocks { get; set; }
    public string PluginName { get; set; }
    public string PluginDescription { get; set; }
}
