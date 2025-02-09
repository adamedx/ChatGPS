//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Models;

public class FunctionTable
{
    public FunctionTable()
    {
        this.functionById = new Dictionary<Guid,Function>();
        this.functionByName = new SortedDictionary<string, Function>(StringComparer.InvariantCultureIgnoreCase);
    }

    public void AddFunction(Function function, bool replace = false)
    {
        lock (this)
        {
            bool hasName = function.Name is not null && function.Name.Length > 0;

            bool checkForExisting = ! replace && hasName;

            // Repeated use of null check here because the compiler's nullable check couldn't traverse variable assignments.
            if ( checkForExisting &&
                 function.Name is not null &&
                 hasName &&
                 this.functionByName.ContainsKey(function.Name) )
            {
                throw new ArgumentException($"The function named '{function.Name}' is already defined");
            }

            this.functionById.Add(function.Id, function);

            if ( hasName && function.Name is not null )
            {
                this.functionByName[function.Name] = function;
            }
        }
    }

    public void RemoveFunction(Guid functionId)
    {
        lock (this)
        {
            string? functionName = this.functionById[functionId]?.Name;

            if ( functionName is not null )
            {
                this.functionByName.Remove(functionName);
            }

            this.functionById.Remove(functionId);
        }
    }

    public Function GetFunctionById(Guid functionId)
    {
        Function targetFunction;

        lock (this)
        {
            targetFunction = functionById[functionId];
        }

        return targetFunction;
    }

    public Function? GetFunctionByName(string name, bool ignoreMissing = false)
    {
        Function? targetFunction = null;

        lock (this )
        {
            if ( ! functionByName.TryGetValue(name, out targetFunction) && ! ignoreMissing )
            {
                throw new KeyNotFoundException($"The specified function named {name} was not found in the current session.");
            }
        }

        return targetFunction;
    }

    public IEnumerable<Function> GetFunctions()
    {
        return functionById.Values;
    }

    public IEnumerable<Function> GetNamedFunctions()
    {
        return functionById.Values;
    }

    private Dictionary<Guid,Function> functionById;
    private SortedDictionary<string,Function> functionByName;
}
