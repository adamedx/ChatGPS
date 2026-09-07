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

using System.Globalization;

namespace Modulus.ChatGPS.Models;

public class AIFunctionResult
{
    public AIFunctionResult()
    {
        this.Content = null;
        this.Culture = null;
        this.TypeName = null;
        this.Metadata = null;
    }

    public AIFunctionResult(string content, Type? resultType, Dictionary<string,object?>? metadata, CultureInfo? culture = null)
    {
        this.Content = content;
        this.Culture = culture;
        this.TypeName = resultType?.FullName;
        this.Metadata = metadata is not null ? new Dictionary<string,object?>(metadata) : null;
    }

    public string? Content { get; private set; }
    public CultureInfo? Culture { get; private set; }
    public string? TypeName { get; private set; }
    public Dictionary<string,object?>? Metadata { get; private set; }
}
