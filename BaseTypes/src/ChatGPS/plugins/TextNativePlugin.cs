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

using System.ComponentModel;

namespace Modulus.ChatGPS.Plugins;

[Description("Allows the local computer to perform string manipulations.")]
public sealed class TextNativePlugin
{
    [Description("Trim whitespace from the start and end of a string.")]
    public string Trim([Description("The string to trim.")] string input)
    {
        return input?.Trim() ?? string.Empty;
    }

    [Description("Trim whitespace from the start of a string.")]
    public string TrimStart([Description("The string to trim.")] string input)
    {
        return input?.TrimStart() ?? string.Empty;
    }

    [Description("Trim whitespace from the end of a string.")]
    public string TrimEnd([Description("The string to trim.")] string input)
    {
        return input?.TrimEnd() ?? string.Empty;
    }

    [Description("Convert a string to uppercase.")]
    public string Uppercase([Description("The string to convert.")] string input)
    {
        return input?.ToUpper(System.Globalization.CultureInfo.CurrentCulture) ?? string.Empty;
    }

    [Description("Convert a string to lowercase.")]
    public string Lowercase([Description("The string to convert.")] string input)
    {
        return input?.ToLower(System.Globalization.CultureInfo.CurrentCulture) ?? string.Empty;
    }

    [Description("Get the length of a string. Returns 0 if null or empty.")]
    public int Length([Description("The string to get the length of.")] string input)
    {
        return input?.Length ?? 0;
    }

    [Description("Concat two strings into one.")]
    public string Concat(
        [Description("First input to concatenate with")] string input,
        [Description("Second input to concatenate with")] string input2)
    {
        return string.Concat(input, input2);
    }

    [Description("Echo the input string. Useful for capturing plan input for use in multiple functions.")]
    public string Echo([Description("Input string to echo.")] string text)
    {
        return text;
    }
}
