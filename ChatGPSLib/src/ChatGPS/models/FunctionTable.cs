//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Services;

internal class FunctionTable
{
    internal FunctionTable()
    {
        this.functionById = new Dictionary<Guid,Function>();
        this.functionByName = new SortedDictionary<string, Function>();
    }

    internal void AddFunction(Function function, bool replace = false)
    {
        lock (this)
        {
            bool hasName = function.Name is not null;

            bool checkForExisting = ! replace && hasName;

            // Repeated use of null check here because the compiler's nullable check couldn't traverse variable assignments.
            if ( checkForExisting && function.Name is not null  && this.functionByName.ContainsKey(function.Name) )
            {
                throw new ArgumentException($"The function named '{function.Name}' is already defined");
            }

            this.functionById.Add(function.Id, function);

            if ( function.Name is not null )
            {
                this.functionByName.Add(function.Name, function);
            }
        }
    }

    internal void RemoveFunction(Guid functionId)
    {
        lock (this)
        {
            var targetFucntion = functionById[functionId];

            string? functionName = this.functionById[functionId]?.Name;

            if ( functionName is not null )
            {
                this.functionByName.Remove(functionName);
            }

            this.functionById.Remove(functionId);
        }
    }

    internal Function GetFunctionById(Guid functionId)
    {
        Function targetFunction;

        lock (this)
        {
            targetFunction = functionById[functionId];
        }

        return targetFunction;
    }

    internal Function? GetFunctionByName(string name, bool ignoreMissing)
    {
        Function? targetFunction = null;

        if ( ! functionByName.TryGetValue(name, out targetFunction) && ignoreMissing )
        {
            throw new KeyNotFoundException($"The specified function named {name} was not found");
        }

        return targetFunction;
    }

    internal IEnumerable<Function> GetFunctions()
    {
        return functionByName.Values;
    }

    internal IEnumerable<Function> GetNamedFunctions()
    {
        return functionById.Values;
    }

    private Dictionary<Guid,Function> functionById;
    private SortedDictionary<string,Function> functionByName;
}
