//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

internal class SendChatCommand : Command
{
    internal SendChatCommand(CommandProcessor processor) : base(processor) {}

    internal override ProxyResponse.Operation[] Process(string[] arguments, bool whatIf = false)
    {
        var operation = new ProxyResponse.Operation("sendchat", Invoke);

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        return "Sendchat executed";
    }
}
