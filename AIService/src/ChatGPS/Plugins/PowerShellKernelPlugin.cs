//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Text.Json;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public abstract class PowerShellKernelPlugin
{
    protected PowerShellKernelPlugin(Dictionary<string,IPowerShellScriptBlock> scriptBlocks)
    {
        this.scriptBlocks = scriptBlocks;
    }

    protected string InvokeFunctionAndReturnAsJson(string functionName, Dictionary<string,object> parameters)
    {
        var result = this.scriptBlocks[functionName].InvokeAndReturnAsJson(parameters);

        return SerializeToJson(result);
    }

    protected void AddScriptBlock(string functionName, IPowerShellScriptBlock scriptBlock)
    {
        scriptBlocks.Add(functionName, scriptBlock);
    }

    virtual protected string SerializeToJson(object? scriptOutput)
    {
        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.MaxDepth = 10;

        return scriptOutput is null ? "" : JsonSerializer.Serialize(scriptOutput, scriptOutput.GetType(), jsonOptions);
    }

    private Dictionary<string,IPowerShellScriptBlock> scriptBlocks;
}
