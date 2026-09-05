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
using System.Text.RegularExpressions;

namespace Modulus.ChatGPS.Services;

public class AIChatFunction
{
	public AIChatFunction(string definitionPrompt)
    {
        this.DefinitionPrompt = definitionPrompt;
        this.Parameters = AIChatFunction.GetParametersFromDefinition(definitionPrompt);
	}

    public string DefinitionPrompt { get; private set; }

    public IReadOnlyList<string> Parameters { get; private set; }

    public string RenderPrompt(Dictionary<string,object?>? parameters)
    {
        string result = this.DefinitionPrompt;

        if ( parameters is not null )
        {
            foreach ( var parameter in this.Parameters )
            {
                if ( parameters.TryGetValue(parameter, out var value) )
                {
                    result = result.Replace("{{$" + parameter + "}}", value?.ToString() ?? "");
                }
            }
        }

        return result;
    }

    internal static List<string> GetParametersFromDefinition(string definition)
    {
        var result = new List<string>();

        foreach ( Match match in AIChatFunction.parameterMatcher.Matches(definition) )
        {
            var parameterName = match.Groups["param"].Value;

            if ( ! result.Contains(parameterName) )
            {
                result.Add(parameterName);
            }
        }

        return result;
    }

    private static readonly Regex parameterMatcher = new Regex("\\{\\{\\$(?<param>[a-zA-Z0-9_]+)\\}\\}", RegexOptions.Compiled);
}
