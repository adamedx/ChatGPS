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

    internal CommandProcessor()
    {
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

        if ( ! this.commandTable.TryGetValue(commandName, out commandFunc) )
        {
            throw new ArgumentException($"The specified command {commandName} does not exist");
        }

        var command = commandFunc.Invoke();

        return command.Process(arguments);
    }

    internal string? RequestExit()
    {
        this.Status = RuntimeStatus.Exited;
        return null;
    }

    internal RuntimeStatus Status { get; private set; }

    private Dictionary<string,Func<Command>> commandTable;
}
