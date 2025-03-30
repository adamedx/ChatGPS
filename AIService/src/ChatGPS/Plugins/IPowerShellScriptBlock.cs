//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public interface IPowerShellScriptBlock
{
    public string Name { get; }
    public string Description { get; }
    public string OutputDescription { get; }
    public Dictionary<string,string> ParameterTable { get; }

    object? InvokeAndReturnAsJson(Dictionary<string,object> parameters);
}
