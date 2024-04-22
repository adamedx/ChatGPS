//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionResponse
{
    public CreateConnectionResponse() {}
    public CreateConnectionResponse( Guid id ) { this.ConnectionId = id; }

    public Guid ConnectionId { get; set; }
}
