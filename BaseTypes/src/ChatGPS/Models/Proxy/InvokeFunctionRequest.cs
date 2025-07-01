//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Models.Proxy;

public class InvokeFunctionRequest : CommandRequest
{
    public InvokeFunctionRequest() {}

    public InvokeFunctionRequest(string definitionPrompt, IEnumerable<Plugin>? plugins, Dictionary<string,object?> parameters, bool? allowFunctionCall)
    {
        this.DefinitionPrompt = definitionPrompt;
        this.Parameters = parameters;
        this.AllowFunctionCall = allowFunctionCall;
        this.Plugins = plugins;
    }

    public string? DefinitionPrompt { get; set; }
    public Dictionary<string,object?>? Parameters { get; set; }
    public bool? AllowFunctionCall { get; set; }
    public IEnumerable<Plugin>? Plugins { get; set; }
}
