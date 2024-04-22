//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel.ChatCompletion;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatRequest
{
    public Guid ConnectionId { get; set; }
    public ChatHistory? History{ get; set; }
}
