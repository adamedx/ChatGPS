//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Services;

internal class Function
{
    internal Function(string[]? parameters = null, string? definition = null )
    {
        // Apparently I have to duplicate code in the actual constructor block itself -- it's not
        // enough for it to be initialized in a method invoked from the constructor??!!!!
        this.Definition = definition ?? "";
        this.Parameters = new SortedList<string,string>();
        Initialize(null, parameters, definition);
    }

    internal Function(string name, string[]? parameters = null, string? definition = null )
    {
        this.Definition = definition ?? ""; // Should not have to do this!
        this.Parameters = new SortedList<string,string>();
        Initialize(name, parameters, definition);
    }

    internal KernelArguments? GetArguments(Dictionary<string,object?>? boundParameters)
    {
        if ( boundParameters is not null )
        {
            foreach ( var parameterName in boundParameters.Keys )
            {
                if ( ! this.Parameters.ContainsKey(parameterName) )
                {
                    throw new ArgumentException($"The specified parameter {parameterName} is not defined for the specified function");
                }
            }
        }

        return boundParameters is not null ? new KernelArguments(boundParameters) : null;
    }

    private void Initialize(string? name, string[]? parameters = default, string? definition = default )
    {
        this.Id = Guid.NewGuid();
        this.Name = name;

        if ( parameters is not null )
        {
            foreach ( var parameter in parameters )
            {
                this.Parameters.Add(parameter, parameter);
            }
        }
    }

    internal Guid Id { get; private set; }
    internal string? Name { get; private set; }
    internal string Definition { get; private set; }
    internal SortedList<string,string> Parameters { get; private set; }
}
