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
        List<AIServiceException> exceptions = new List<AIServiceException>();

        ProxyResponse.ResponseStatus responseStatus = ProxyResponse.ResponseStatus.Unknown;

        foreach ( ProxyResponse.Operation operation in operations )
        {
            if ( ! this.WhatIfMode || commandFunc is null )
            {
                if ( operation.Status != ProxyResponse.Operation.OperationStatus.Error )
                {
                    responseStatus = ProxyResponse.ResponseStatus.Success;

                    var result = operation.Result ?? "";
                    content.Add(result);
                    Logger.Log($"Successfully executed '{operation.Name}' with response of size {result.Length}");
                    Logger.Log($"Operation {operation.Name} returned result: {result}", Logger.LogLevel.DebugVerbose);
                }
                else
                {
                    responseStatus = ProxyResponse.ResponseStatus.Error;

                    // This is an System.AggregateException, so the inner exception is the real exception
                    var responseException = operation.OperationException ??
                        new AIServiceException("An error occurred but no exception information was provided.");

                    var errorMessage = responseException.Message ?? "An unspecified error occurred";
                    var sourceExceptionMessage = $"Failed to execute {operation.Name} with error: {errorMessage}";

                    var targetException = responseException is AggregateException ?
                        responseException.InnerException :
                        responseException;

                    var translatedMessage = targetException is AIServiceException ? ((AIServiceException) targetException).OriginalMessage : sourceExceptionMessage;

                    var exceptionMessage = translatedMessage ?? "An unspecified error occurred from a nested exception.";

                    Logger.Log(exceptionMessage, Logger.LogLevel.Error);

                    var resultException = AIServiceException.CreateServiceException(exceptionMessage, targetException);

                    exceptions.Add(resultException);
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
