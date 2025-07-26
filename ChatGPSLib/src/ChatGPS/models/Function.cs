//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using  Modulus.ChatGPS.Services;

namespace Modulus.ChatGPS.Models;

public class Function
{
    public Function(string[]? parameters = null, string? definition = null )
    {
        // Apparently I have to duplicate code in the actual constructor block itself -- it's not
        // enough for it to be initialized in a method invoked from the constructor??!!!!
        this.Definition = definition ?? "";
        this.Parameters = new SortedList<string,string>();
        Initialize(null, parameters, definition);
    }

    public Function(string? name, string[]? parameters = null, string? definition = null )
    {
        this.Definition = definition ?? ""; // Should not have to do this!
        this.Parameters = new SortedList<string,string>();
        Initialize(name, parameters, definition);
    }

    public async Task<string> InvokeFunctionAsync(IChatService chatService, Dictionary<string,object?>? boundParameters, bool? allowAgentAccess = null)
    {
        ValidateParameters(boundParameters);

        var response = await chatService.InvokeFunctionAsync(this.Definition, boundParameters, allowAgentAccess);

        return response.Result ?? "";
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

    private void ValidateParameters(Dictionary<string,object?>? boundParameters)
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
    }

    public Guid Id { get; private set; }
    public string? Name { get; private set; }
    public string Definition { get; private set; }
    public SortedList<string,string> Parameters { get; private set; }
}

