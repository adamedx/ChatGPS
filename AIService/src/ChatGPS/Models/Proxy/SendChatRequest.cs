//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel.ChatCompletion;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatRequest : CommandRequest
{
    public SendChatRequest() {}

    public SendChatRequest(ChatHistory chatHistory, bool? allowFunctionCall = null)
    {
        this.History = chatHistory;
    }

    public ChatHistory? History { get; set; }
    public bool? AllowFunctionCall { get; set; }
}
