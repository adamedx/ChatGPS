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

    // This constructor is used by clients without access to SK types
    public SendChatRequest(ChatMessageHistory chatHistory, IEnumerable<PluginInfo>? plugins, bool? allowFunctionCall)
    {
        this.History = chatHistory.SourceHistory;
        this.AllowFunctionCall = allowFunctionCall;
        this.Plugins = plugins;
    }

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
