//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatResponse : CommandResponse
{
    public SendChatResponse() {}

    public SendChatResponse( string? responseMessage = null, AuthorRole? role = null )
    {
        if ( responseMessage is not null )
        {
            this.ChatResponse = new ChatMessageContent( role ?? AuthorRole.Assistant, responseMessage );
        }
    }

    public ChatMessageContent? ChatResponse { get; set; }
}
