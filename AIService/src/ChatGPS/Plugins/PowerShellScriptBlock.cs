//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellScriptBlockBase : IPowerShellScriptBlock
{
    public PowerShellScriptBlockBase(string name, string description, string? outputDescription = null)
    {
        this.Name = name;
        this.Description = description;
        this.OutputDescription = outputDescription ?? "This function returns no output; it only produces side effects";
        this.ParameterTable = new Dictionary<string,string>();
    }

    public string Name { get; set; }
    public string Description { get;  set; }
    public string OutputDescription { get; set; }
    public Dictionary<string,string> ParameterTable { get; set; }

    public object? InvokeAndReturnAsJson(Dictionary<string,object> parameters)
    {
        throw new NotImplementedException("This method must be overridden");
    }
}
