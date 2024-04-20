//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

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
        this.commandTable = new Dictionary<string,Func<Command>> {
            { "exit", () => { return new ExitCommand(this); } },
            { "sendchat", () => { return new SendChatCommand(this); } }
        };
    }

    internal string? InvokeCommand(string commandName, string[] arguments)
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

            operations = command.Process(arguments, this.WhatIfMode);
        }
        else
        {
            var operationException = new ArgumentException($"The specified command {commandName} does not exist");
            var failedOperation = new ProxyResponse.Operation($"InvokeCommand-{commandName}", operationException);

            operations = new ProxyResponse.Operation[] { failedOperation };
        }

        string? result = operations.Length > 0 ? "" : null;

        foreach ( ProxyResponse.Operation operation in operations )
        {
            if ( ! this.WhatIfMode || commandFunc is null )
            {
                if ( operation.Status != ProxyResponse.Operation.OperationStatus.Error )
                {
                    result += $"\n\t\tSUCCESS: Successfully executed {operation.Name} with result: {operation.Result}";
                }
                else
                {
                    var errorMessage = operation.OperationException?.Message ?? "";
                    result += $"\n\t\tERROR: Failed to execute {operation.Name} with exception: {errorMessage}";
                }
            }
            else
            {
                result += $"\n\t\tOPERATION: Would execute {operation.Name}";
            }
        }

        return result;
    }

    internal string? RequestExit()
    {
        this.Status = RuntimeStatus.Exited;
        return null;
    }

    internal bool WhatIfMode { get; private set; }
    internal RuntimeStatus Status { get; private set; }

    private Dictionary<string,Func<Command>> commandTable;
}
