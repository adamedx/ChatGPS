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

    internal Connection NewConnection(AiOptions? options)
    {
        if ( options is null )
        {
            throw new ArgumentException($"No connection options were specified for connecting to the service.");
        }

        ServiceBuilder builder = ServiceBuilder.CreateBuilder();

        builder.WithOptions(options);

        var newService = builder.Build();
        var connection = new Connection( Guid.NewGuid(), newService );

        connections.Add(connection.Id, connection);

        Logger.Log($"Added new connection with id {connection.Id} for provider {options.Provider}");

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
