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

    public InvokeFunctionRequest(string definitionPrompt, IEnumerable<PluginInfo>? plugins, Dictionary<string,object?> parameters)
    {
        this.DefinitionPrompt = definitionPrompt;
        this.Parameters = parameters;
        this.Plugins = plugins;
    }

    public string? DefinitionPrompt { get; set; }
    public Dictionary<string,object?>? Parameters { get; set; }
    public IEnumerable<PluginInfo>? Plugins { get; set; }
}
