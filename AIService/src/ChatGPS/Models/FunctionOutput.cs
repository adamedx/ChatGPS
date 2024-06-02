//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Globalization;

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Models;

public class FunctionOutput
{
    public FunctionOutput() {}

    public FunctionOutput(FunctionResult functionResult)
    {
        this.CultureName = functionResult.Culture.Name;
        this.Result = functionResult.GetValue<string>();
        this.Metadata = functionResult.Metadata is not null ?  new Dictionary<string,object?>(functionResult.Metadata) : null;
        this.ValueTypeName = functionResult.ValueType?.FullName;
        this.RenderedPrompt = functionResult.RenderedPrompt;
    }

    public string? Result {get; set;}
    public Dictionary<string,object?>? Metadata { get; set; }
    public string? CultureName { get; set; }
    public string? ValueTypeName {get; set; }
    public string? RenderedPrompt { get; set; }
}
