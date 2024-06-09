//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models.Proxy;

internal class ExitCommand : Command
{
    internal ExitCommand(CommandProcessor processor) : base(processor) {}

    internal override ProxyResponse.Operation[] Process(CommandRequest? request, bool whatIf = false)
    {
        var operation = new ProxyResponse.Operation("exit", Invoke);

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        this.processor.RequestExit();
        return null;
    }
}
