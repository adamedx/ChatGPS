//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Models.Proxy;

public class InvokeFunctionResponse : CommandResponse
{
    public InvokeFunctionResponse() {}

    public InvokeFunctionResponse( FunctionOutput? output )
    {
        this.Output = output;
    }

    public FunctionOutput? Output { get; set; }
}
