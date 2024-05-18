//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Proxy;

internal class ProxyConnection
{
    internal ProxyConnection(ServiceBuilder.ServiceId serviceId, int idleTimeoutMs)
    {
        this.idleTimeoutMs = idleTimeoutMs;
        this.channel = new Channel(idleTimeoutMs);
    }
/*
    internal async Task SendMessageAsync(string message)
    {
        throw new NotImplementedException();
    }

    internal async Task<string> ReadMessageAsync()
    {
        throw new NotImplementedException();
    }
*/
    Channel channel;
    int idleTimeoutMs;
//    Guid connectionId;
}


