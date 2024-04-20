//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

internal class ExitCommand : Command
{
    internal ExitCommand(CommandProcessor processor) : base(processor) {}

    internal override string? Process(string[] arguments)
    {
        string? result = null;

        try
        {
            result = this.processor.RequestExit();
        }
        catch
        {
        }

        return result;
    }
}
