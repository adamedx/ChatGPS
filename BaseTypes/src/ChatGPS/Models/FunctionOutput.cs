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
using System.Globalization;

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Models;

public class FunctionOutput
{
    public FunctionOutput() {}

    public FunctionOutput(FunctionResult functionResult)
    {
        this.CultureName = functionResult.Culture.Name;
        this.Result = functionResult.GetValue<string>();
        this.Metadata = functionResult.Metadata is not null ?  new Dictionary<string,object?>(functionResult.Metadata) : null;
        this.ValueTypeName = functionResult.ValueType?.FullName;
        this.RenderedPrompt = null;
    }

    public string? Result {get; set;}
    public Dictionary<string,object?>? Metadata { get; set; }
    public string? CultureName { get; set; }
    public string? ValueTypeName {get; set; }
    public string? RenderedPrompt { get; set; }
}

