//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

namespace Modulus.ChatGPS.Proxy;

internal class ProxyConnection
{
    internal ProxyConnection(ServiceBuilder.ServiceId serviceId, AiOptions options, int idleTimeoutMs)
    {
        this.serviceId = serviceId;
        this.idleTimeoutMs = idleTimeoutMs;
        this.channel = new Channel(idleTimeoutMs);
        this.options = options;
    }

    internal async Task SendRequestAsync(ProxyRequest request)
    {
        var connectedRequest = new ProxyRequest(request);

        connectedRequest.TargetConnectionId = this.serviceConnectionId;

        var message = connectedRequest.ToSerializedMessage();

        if ( message is null )
        {
            throw new ArgumentException("The serialized message was not valid");
        }

        await this.channel.SendMessageAsync(message);

        return;
    }

    internal async Task<ProxyResponse> ReadResponseAsync()
    {
        var message = await this.channel.ReadMessageAsync();

        return (ProxyResponse) ProxyResponse.FromSerializedMessage(message, typeof(ProxyResponse));
    }

    internal void BindTargetService(Guid targetConnectionId)
    {
        if ( targetConnectionId == Guid.Empty )
        {
            throw new ArgumentException("The specified connection id was an empty guid and not a valid connection identifier");
        }

        if ( this.serviceId is null )
        {
            throw new ArgumentException("The specified target service connection identifier was not specified");
        }

        if ( this.serviceConnectionId != Guid.Empty )
        {
            throw new InvalidOperationException("The connection is already bound to a target service");
        }

        this.serviceConnectionId = targetConnectionId;
    }

    internal void ResetTargetServiceBinding()
    {
        this.serviceConnectionId = Guid.Empty;
    }

    internal bool IsConnectedToAiService
    {
        get
        {
            return this.serviceConnectionId != Guid.Empty;
        }
    }

    internal AiOptions? ServiceOptions
    {
        get
        {
            return this.options;
        }
    }

    ServiceBuilder.ServiceId? serviceId;
    AiOptions options;
    IChannel channel;
    Guid serviceConnectionId;
    int idleTimeoutMs;
  }


