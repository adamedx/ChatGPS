//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Threading;

namespace Modulus.ChatGPS.Models;

public class Plugin
{
    internal Plugin(Guid pluginId, ICollection<NativeFunction> functions, string? name)
    {
        this.functions = new Dictionary<string, NativeFunction>();

        foreach ( var function in functions )
        {
            if ( function.Name is not null )
            {
                this.functions.Add(function.Name, function);
            }
            else
            {
                throw new ArgumentException("A function was specified without a non-null name");
            }
        }
    }

    private Dictionary<string, NativeFunction> functions;
}
