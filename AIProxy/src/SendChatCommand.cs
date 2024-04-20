//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

internal class SendChatCommand : Command
{
    internal SendChatCommand(CommandProcessor processor) : base(processor) {}

    internal override string? Process(string[] arguments)
    {
        return "Sendchat executed";
    }
}
