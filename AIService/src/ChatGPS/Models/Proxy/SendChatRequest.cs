//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatRequest : CommandRequest
{
    public SendChatRequest() {}

    public SendChatRequest(ChatHistory chatHistory, IEnumerable<PluginInfo>? plugins, bool? allowFunctionCall)
    {
        this.History = chatHistory;
        this.AllowFunctionCall = allowFunctionCall;
        this.Plugins = plugins;
    }

    public ChatHistory? History { get; set; }
    public bool? AllowFunctionCall { get; set; }
    public IEnumerable<PluginInfo>? Plugins { get; set; }
}
