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

using Microsoft.SemanticKernel;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public abstract class PowerShellPluginBase
{
    public static object Invoke(PowerShellPluginBase plugin, Dictionary<string,object> parameters)
    {
        return plugin.Invoke(parameters);
    }

    public int GetVal() { return 5; }

    public Func<int> GetFunc() { return GetVal; }

    public abstract object Invoke(Dictionary<string,object> parameters);
}

