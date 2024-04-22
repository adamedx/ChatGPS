//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionRequest
{
    public ServiceBuilder.ServiceId ServiceId { get; set; }
    public AiOptions? ConnectionOptions { get; set; }
}
