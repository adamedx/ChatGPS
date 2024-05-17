//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionRequest : CommandRequest
{
    public ServiceBuilder.ServiceId ServiceId { get; set; }
    public AiOptions? ConnectionOptions { get; set; }
}
