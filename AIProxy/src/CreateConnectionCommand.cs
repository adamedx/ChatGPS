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

    internal override ProxyResponse.Operation[] Process(CommandRequest? request, bool whatIf = false)
    {
        if ( request is null )
        {
            throw new ArgumentException("createconnection command missing required arguments");
        }

        this.connectionArguments = (CreateConnectionRequest) request;

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

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<CreateConnectionResponse>(response, jsonOptions);
    }

    private CreateConnectionRequest? connectionArguments;
}
