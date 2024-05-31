//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;
using Modulus.ChatGPS.Services;

internal class ConnectionManager
{
    internal ConnectionManager()
    {
        this.connections = new Dictionary<Guid, Connection>();
    }

    internal Connection NewConnection(ServiceBuilder.ServiceId serviceId, AiOptions? options)
    {
        if ( serviceId != ServiceBuilder.ServiceId.AzureOpenAi )
        {
            throw new ArgumentException($"The specified service {serviceId} is not supported");
        }

        if ( options is null )
        {
            throw new ArgumentException($"No connection options were specified for connecting to the service 'serviceId'.");
        }

        var newService = new OpenAIChatService(options);
        var connection = new Connection( Guid.NewGuid(), newService);

        connections.Add(connection.Id, connection);

        Logger.Log($"Added new connection with id {connection.Id} for service id {serviceId}");

        return connection;
    }

    internal Connection GetConnection(Guid connectionId, bool failIfNotFound = false)
    {
        ValidateConnection(connectionId, failIfNotFound);

        return this.connections[connectionId];
    }

    internal void RemoveConnection(Guid connectionId, bool failIfNotFound = false)
    {
        ValidateConnection(connectionId, failIfNotFound);

        this.connections.Remove(connectionId);
    }

    private void ValidateConnection(Guid connectionId, bool failIfNotFound)
    {
        if ( ! failIfNotFound && ! this.connections.ContainsKey(connectionId) )
        {
            throw new ProxyException($"The connection with identifier {connectionId} does not exist",
                                     new (string,object)[] { (ProxyException.ExceptionType.BadConnection.ToString(), connectionId) } );
        }
    }

    private Dictionary<Guid, Connection> connections;
}
