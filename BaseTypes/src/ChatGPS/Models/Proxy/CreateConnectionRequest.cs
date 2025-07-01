//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionRequest : CommandRequest
{
    public CreateConnectionRequest() {}

    public CreateConnectionRequest( AiOptions connectionOptions )
    {
        this.ConnectionOptions = connectionOptions;
    }

    public AiOptions? ConnectionOptions { get; set; }
}
