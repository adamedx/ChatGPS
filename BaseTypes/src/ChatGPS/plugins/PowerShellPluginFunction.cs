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
using System.Collections.ObjectModel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellPluginFunction
{
    public PowerShellPluginFunction(string name, string scriptBlock, Dictionary<string,string> parameterTable, string description, string? outputType, string? outputDescription = null)
    {
        this.Name = name;
        this.Description = description;
        this.OutputType = outputType;
        this.OutputDescription = outputDescription ?? "This function returns no output; it only produces side effects";
        this.ScriptBlock = scriptBlock;
        this.ParameterTable = parameterTable;
    }

    public PowerShellPluginFunction()
    {
        this.ParameterTable = new Dictionary<string,string>();
    }

    public ReadOnlyDictionary<string,string> GetParameterTable()
    {
        if ( this.ScriptBlock is null )
        {
            throw new InvalidOperationException("The object has no scriptblock and is not in a valid state to be accessed.");
        }

        return new ReadOnlyDictionary<string,string>(this.ParameterTable);
    }

    public string? Name { get; set; }
    public string? Description { get;  set; }
    public string? OutputType { get; set; }
    public string? OutputDescription { get; set; }
    public string? ScriptBlock { get; set; }
    public Dictionary<string,string> ParameterTable {get; set;}
}

