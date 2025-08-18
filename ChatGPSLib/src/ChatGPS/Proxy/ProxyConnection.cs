//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;
using Modulus.ChatGPS.Communication;

namespace Modulus.ChatGPS.Proxy;

internal class ProxyConnection
{
    internal ProxyConnection(Transport transport, AiOptions options, string proxyHostPath, string? logFilePath = null, string? logLevel = null, int idleTimeoutMs = 60000)
    {
        this.transport = transport;
        this.idleTimeoutMs = idleTimeoutMs;
        this.channel = new Channel(proxyHostPath, idleTimeoutMs, logFilePath, logLevel);
        this.options = options;
        this.connectionInProgress = false;
    }

    internal async Task SendRequestAsync(ProxyRequest request)
    {
        ConnectAiService();

        var connectedRequest = new ProxyRequest(request);

        connectedRequest.TargetConnectionId = this.serviceConnectionId;

        var message = connectedRequest.ToSerializedMessage();

        if ( message is null )
        {
            throw new ProxyException("The request could not be serialized");
        }

        await this.channel.SendMessageAsync(message);

        return;
    }

    internal async Task<ProxyResponse> ReadResponseAsync()
    {
        var message = await this.channel.ReadMessageAsync();

        if ( message is null )
        {
            throw new ProxyException("An unexpected response was returned from the proxy");
        }

        return (ProxyResponse) ProxyResponse.FromSerializedMessage(message, typeof(ProxyResponse));
    }

    internal void BindTargetService(Guid targetConnectionId)
    {
        if ( targetConnectionId == Guid.Empty )
        {
            throw new ArgumentException("The specified connection id was an empty guid and not a valid connection identifier");
        }

        if ( this.serviceConnectionId != Guid.Empty )
        {
            throw new InvalidOperationException("The connection is already bound to a target service");
        }

        this.serviceConnectionId = targetConnectionId;
        this.connectionInProgress = false;
    }

    internal void ResetTargetServiceBinding()
    {
        this.serviceConnectionId = Guid.Empty;
        this.connectionInProgress = false;
    }

    internal bool IsConnectedToAiService
    {
        get
        {
            return this.serviceConnectionId != Guid.Empty;
        }
    }

    internal AiOptions ServiceOptions
    {
        get
        {
            return this.options;
        }
    }

    private async Task SendRequestNoRetryAsync(ProxyRequest request)
    {
        ConnectAiService();

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

    private void ConnectAiService()
    {
        if ( ! IsConnectedToAiService && ! this.connectionInProgress )
        {
            this.connectionInProgress = true;

            try
            {
                var createConnectionRequest = new CreateConnectionRequest();
                createConnectionRequest.ConnectionOptions = this.ServiceOptions;

                var request = ProxyRequest.FromRequestCommand(createConnectionRequest);

                var task = transport.SendAsync(this, request);

                var response = task.Result;

                var createConnectionResponse = (CreateConnectionResponse?) ProxyResponse.GetCommandResponseFromProxyResponse(response, typeof(CreateConnectionResponse));

                if ( createConnectionResponse is null )
                {
                    throw new AIServiceException("Unable to create a connection to the service proxy because the proxy response was empty or otherwise invalid");
                }

                if ( response.Status != ProxyResponse.ResponseStatus.Success )
                {
                    Exception? innerException = ( response.Exceptions != null && response.Exceptions.Length > 0 ) ? response.Exceptions[0] : null;

                    throw AIServiceException.CreateServiceException("The request to establish a connection to a service proxy failed.", innerException);
                }

                BindTargetService(createConnectionResponse.ConnectionId);

                if ( createConnectionResponse.CurrentOptions is not null )
                {
                    // This constructor treats this as the base type which has
                    // no sensitive fields so the resulting object will
                    // be free of such data.
                    this.options = new AiOptions(createConnectionResponse.CurrentOptions);
                }
            }
            finally
            {
                this.connectionInProgress = false;
            }
        }
    }

    Transport transport;

    AiOptions options;
    IChannel channel;
    Guid serviceConnectionId;
    int idleTimeoutMs;
    bool connectionInProgress;
  }

