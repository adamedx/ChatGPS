//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;

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
        this.commandTable = new Dictionary<string,Func<Command>> {
            { "createconnection", () => { return new CreateConnectionCommand(this); } },
            { "exit", () => { return new ExitCommand(this); } },
            { "sendchat", () => { return new SendChatCommand(this); } }
        };
    }

    internal string? InvokeCommand(string commandName, string? arguments)
    {
        if ( this.Status == RuntimeStatus.Exited )
        {
            throw new InvalidOperationException("The commmand may not be invoked because the command processor has already terminated.");
        }

        Func<Command>? commandFunc;

        ProxyResponse.Operation[] operations;

        if ( this.commandTable.TryGetValue(commandName, out commandFunc) )
        {
            var command = commandFunc.Invoke();

            try
            {
                operations = command.Process(arguments, this.WhatIfMode);
            }
            catch (Exception e)
            {
                var commandFailedOperation = new ProxyResponse.Operation($"The attempt to execute commad '{commandName}' failed.", e);
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

        foreach ( ProxyResponse.Operation operation in operations )
        {
            if ( ! this.WhatIfMode || commandFunc is null )
            {
                if ( operation.Status != ProxyResponse.Operation.OperationStatus.Error )
                {
                    content.Add(operation.Result ?? "");
                    Logger.Log($"Successfully executed {operation.Name} with result: {operation.Result}");
                }
                else
                {
                    var targetException = operation.OperationException ??
                        new ProxyException("An unspecified error occurred", new ArgumentException("An unexpected error occurred"));
                    var errorMessage = targetException.Message ?? "An unspecified error occurred";
                    var exceptionMessage = $"Failed to execute {operation.Name} with error: {errorMessage}";

                    Logger.Log(exceptionMessage);

                    exceptions.Add( new ProxyException(exceptionMessage, targetException) );
                }
            }
            else
            {
                Logger.Log($"\n\t\tOPERATION: Would execute {operation.Name}");
            }
        }

        ProxyResponse response;

        if ( ! this.WhatIfMode )
        {
            response = new ProxyResponse(content.ToArray(), exceptions.ToArray());
        }
        else
        {
            response = new ProxyResponse(operations);
        }

        var result = JsonSerializer.Serialize<ProxyResponse>(response);

        return result;
    }

    internal string? RequestExit()
    {
        this.Status = RuntimeStatus.Exited;
        return null;
    }

    internal bool WhatIfMode { get; private set; }
    internal RuntimeStatus Status { get; private set; }

    internal ConnectionManager Connections { get; private set; }

    private Dictionary<string,Func<Command>> commandTable;
}
