//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel.ChatCompletion;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatRequest : CommandRequest
{
    public SendChatRequest(Guid connectionId) : base ( connectionId ) {}
    public SendChatRequest() {}

    public ChatHistory? History{ get; set; }
}
