//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionResponse : CommandResponse
{
    public CreateConnectionResponse() {}
    public CreateConnectionResponse( Guid id, AiOptions currentOptions )
    {
        this.ConnectionId = id;
        this.CurrentOptions = new AiProviderOptions( new AiOptions(currentOptions) );
    }

    public Guid ConnectionId { get; set; }
    public AiProviderOptions? CurrentOptions { get; set; }
}
