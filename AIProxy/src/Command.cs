//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

//
// Note that we can't inherit from an interface because
// any methods implemented for an interface MUST be
// public according to some arbitrary C# rule or you
// end up with error CS0737. We were going to have this
// abstract class inherit from it, but since everyone
// is going to inherit from this abstract class, we
// might as well just pretend this class is the interface. :)
//

internal abstract class Command
{
    protected Command(CommandProcessor processor)
    {
        this.processor = processor;
    }

    internal abstract ProxyResponse.Operation[] Process(CommandRequest? commandRequest, bool whatIf = false);

    protected CommandProcessor processor;
}
