//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

internal class CommandProcessor
{
    internal enum RuntimeStatus
    {
        Ready,
        Exited
    }

    internal CommandProcessor(bool whatIfMode = false)
    {
        this.WhatIfMode = whatIfMode;
        this.Connections = new ConnectionManager();
        this.commandTable = new Dictionary<string,Func<Guid, Command>>
        {
            { "createconnection", (connectionId) => { return new CreateConnectionCommand(this); } },
            { "exit", (connectionId) => { return new ExitCommand(this); } },
            { "sendchat", (connectionId) => { return new SendChatCommand(this, connectionId); } }
        };
    }

    internal string? InvokeCommand(Guid requestId, string commandName, CommandRequest? commandRequest, Guid serviceConnectionId)
    {
        if ( this.Status == RuntimeStatus.Exited )
        {
            throw new InvalidOperationException("The command may not be invoked because the command processor has already terminated.");
        }

        Func<Guid, Command>? commandFunc;

        ProxyResponse.Operation[] operations;

        if ( this.commandTable.TryGetValue(commandName, out commandFunc) )
        {
            var command = commandFunc.Invoke(serviceConnectionId);

            try
            {
                operations = command.Process(commandRequest, this.WhatIfMode);
            }
            catch (Exception e)
            {
                var commandFailedOperation = new ProxyResponse.Operation($"The attempt to execute command '{commandName}' failed.", e);
                operations = new ProxyResponse.Operation[] { commandFailedOperation };
            }
        }
        else
        {
            var operationException = new ArgumentException($"The specified command {commandName} does not exist.");
            var notFoundOperation = new ProxyResponse.Operation($"InvokeCommand-{commandName}", operationException);

            operations = new ProxyResponse.Operation[] { notFoundOperation };
        }


        List<string> content = new List<string>();
        List<ProxyException> exceptions = new List<ProxyException>();

        ProxyResponse.ResponseStatus responseStatus = ProxyResponse.ResponseStatus.Unknown;

        foreach ( ProxyResponse.Operation operation in operations )
        {
            if ( ! this.WhatIfMode || commandFunc is null )
            {
                if ( operation.Status != ProxyResponse.Operation.OperationStatus.Error )
                {
                    responseStatus = ProxyResponse.ResponseStatus.Success;

                    content.Add(operation.Result ?? "");
                    Logger.Log($"Successfully executed {operation.Name} with result: {operation.Result}");
                }
                else
                {
                    responseStatus = ProxyResponse.ResponseStatus.Error;

                    var targetException = operation.OperationException ??
                        new ProxyException("An unspecified error occurred", new ProxyException(new ArgumentException("An unexpected error occurred")));
                    var errorMessage = targetException.Message ?? "An unspecified error occurred";
                    var exceptionMessage = $"Failed to execute {operation.Name} with error: {errorMessage}";

                    Logger.Log(exceptionMessage);

                    exceptions.Add( new ProxyException(exceptionMessage, new ProxyException(targetException)) );
                }
            }
            else
            {
                responseStatus = ProxyResponse.ResponseStatus.Success;
                Logger.Log($"\n\t\tOPERATION: Would execute {operation.Name}");
            }
        }

        ProxyResponse response;

        if ( ! this.WhatIfMode )
        {
            response = new ProxyResponse(requestId, responseStatus, content.ToArray(), exceptions.ToArray());
        }
        else
        {
            response = new ProxyResponse(requestId, responseStatus, operations);
        }

        return response.ToSerializedMessage();
    }

    internal string? RequestExit()
    {
        this.Status = RuntimeStatus.Exited;
        return null;
    }

    internal bool WhatIfMode { get; private set; }
    internal RuntimeStatus Status { get; private set; }

    internal ConnectionManager Connections { get; private set; }

    private Dictionary<string,Func<Guid, Command>> commandTable;
}
