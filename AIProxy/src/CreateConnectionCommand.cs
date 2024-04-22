//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using Modulus.ChatGPS.Models;

using Modulus.ChatGPS.Models.Proxy;

internal class CreateConnectionCommand : Command
{
    internal CreateConnectionCommand(CommandProcessor processor) : base(processor) {}

    internal override ProxyResponse.Operation[] Process(string? arguments, bool whatIf = false)
    {
        if ( arguments is null )
        {
            throw new ArgumentException("No argument string was specified");
        }

        var connectionArguments = JsonSerializer.Deserialize<CreateConnectionRequest>(arguments);

        this.connectionArguments = connectionArguments;

        var operation = new ProxyResponse.Operation("createconnection", Invoke);

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        if ( this.connectionArguments is null )
        {
            throw new ArgumentException("No connection arguments were specified");
        }

        var newConnection = this.processor.Connections.NewConnection(this.connectionArguments.ServiceId, this.connectionArguments.ConnectionOptions);
        var response = new CreateConnectionResponse(newConnection.Id);

        return JsonSerializer.Serialize<CreateConnectionResponse>(response);
    }

    private CreateConnectionRequest? connectionArguments;
}
