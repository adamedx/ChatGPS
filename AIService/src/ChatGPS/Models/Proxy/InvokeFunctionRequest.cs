//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models.Proxy;

public class InvokeFunctionRequest : CommandRequest
{
    public InvokeFunctionRequest() {}

    public InvokeFunctionRequest(string definitionPrompt, Dictionary<string,object?> parameters)
    {
        this.DefinitionPrompt = definitionPrompt;
        this.Parameters = parameters;
    }

    public string? DefinitionPrompt { get; set; }
    public Dictionary<string,object?>? Parameters { get; set; }
}
