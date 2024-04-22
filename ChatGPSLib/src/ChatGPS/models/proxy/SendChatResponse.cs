//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatResponse
{
    public SendChatResponse() {}
    public SendChatResponse( string? chatResponse ) {
        this.ChatResponse = chatResponse;
    }

    public string? ChatResponse { get; set; }
}
