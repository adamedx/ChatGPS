//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

using Modulus.ChatGPS.Models.Proxy;

internal class InvokeFunctionCommand : Command
{
    internal InvokeFunctionCommand(CommandProcessor processor, Guid serviceConnectionId) : base(processor)
    {
        this.serviceConnectionId = serviceConnectionId;
    }

    internal override ProxyResponse.Operation[] Process(CommandRequest? arguments, bool whatIf = false)
    {
        if ( arguments is null )
        {
            throw new ArgumentException("invokefunction command missing required arguments");
        }

        var operation = new ProxyResponse.Operation("invokefunction", Invoke);

        this.arguments = (InvokeFunctionRequest) arguments;

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        if ( this.arguments is null || this.arguments.DefinitionPrompt is null || this.arguments.Parameters is null )
        {
            throw new ArgumentException("Invalid arguments specified for invokefunction command");
        }

        var connection = this.processor.Connections.GetConnection(this.serviceConnectionId);

        PluginTable.SynchronizePlugins(connection.ChatService, this.arguments.Plugins);

        var task = connection.ChatService.InvokeFunctionAsync(this.arguments.DefinitionPrompt, this.arguments.Parameters, this.arguments.AllowFunctionCall);

        var result = task.Result;

        var response = new InvokeFunctionResponse( result );

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<InvokeFunctionResponse>(response, jsonOptions);
    }

    InvokeFunctionRequest? arguments;
    private Guid serviceConnectionId;
}

