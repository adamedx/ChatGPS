//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public abstract class PowerShellPluginBase
{
    public static object Invoke(PowerShellPluginBase plugin, Dictionary<string,object> parameters)
    {
        return plugin.Invoke(parameters);
    }

    public int GetVal() { return 5; }

    public Func<int> GetFunc() { return GetVal; }

    public abstract object Invoke(Dictionary<string,object> parameters);
}
