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

namespace Modulus.ChatGPS.Plugins;

public class Plugin
{
    public Plugin() {}

    public Plugin(string name, PluginProvider provider, Dictionary<string,PluginParameterValue>? parameters)
    {
        this.Name = name;
        this.Parameters = parameters is not null ? new Dictionary<string,PluginParameterValue>(parameters, StringComparer.OrdinalIgnoreCase) : null;
        this.Id = Guid.NewGuid();
        this.PluginDataJson = provider.GetProviderDataJson();
        this.PluginType = provider.GetType().FullName;
    }

    internal void BindKernelPlugin(KernelPlugin kernelPlugin)
    {
        if ( this.kernelPlugin is not null )
        {
            throw new InvalidOperationException("The object is already bound to an existing kernel plugin");
        }

        this.kernelPlugin = kernelPlugin;
    }

    internal KernelPlugin? GetKernelPlugin()
    {
        return this.kernelPlugin;
    }

    public string? Name { get; set; }
    public Dictionary<string,PluginParameterValue>? Parameters { get; set; }
    public Guid? Id { get; set; }
    public string[]? PluginDataJson { get; set; }
    public string? PluginType { get; set ; }

    private KernelPlugin? kernelPlugin;
}

