//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Management.Automation;

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellScriptBlock
{
    public PowerShellScriptBlock(string name, string scriptBlock, Dictionary<string,string> parameterTable, string description, string? outputType, string? outputDescription = null)
    {
        this.Name = name;
        this.Description = description;
        this.OutputType = outputType;
        this.OutputDescription = outputDescription ?? "This function returns no output; it only produces side effects";
        this.ScriptBlock = scriptBlock;
        this.ParameterTable = parameterTable;
    }

    public PowerShellScriptBlock() {}

    public string? Name { get; set; }
    public string? Description { get;  set; }
    public string? OutputType { get; set; }
    public string? OutputDescription { get; set; }
    public string? ScriptBlock { get; set; }
    public Dictionary<string,string>? ParameterTable { get; set; }
}
