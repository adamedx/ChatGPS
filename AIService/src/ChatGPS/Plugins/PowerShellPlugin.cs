//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellPlugin : Plugin
{
    internal PowerShellPlugin() : base("PowerShellScriptBlock", true)
    {
        this.functions = new Dictionary<string,IPowerShellScriptBlock>();
    }

    public void Add(string name, IPowerShellScriptBlock scriptBlock)
    {
        functions.Add(name, scriptBlock);
    }

    internal override object GetNativeInstance(object[]? parameters = null)
    {
        int parameterCount = 0;
        object? result = null;

        if ( parameters is not null )
        {
            parameterCount = parameters.Length;

            if ( parameterCount == 1 )
            {
                result = parameters[0];
            }
        }

        if ( result is null )
        {
            throw new ArgumentException($"The count of parameters to the Powershell plugin was {parameterCount}; the count must be exactly 1.");
        }

        return result;
    }

    internal object? InvokeFunction(string name, Dictionary<string,object> parameters)
    {
        return functions[name].InvokeAndReturnAsJson(parameters);
    }

    private Dictionary<string,IPowerShellScriptBlock> functions;
}
