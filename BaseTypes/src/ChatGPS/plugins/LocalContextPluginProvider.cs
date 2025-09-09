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

namespace Modulus.ChatGPS.Plugins;

public class LocalContextPluginProvider : PluginProvider
{
    internal LocalContextPluginProvider() : base("LocalContext")
    {
        this.Description = "Enables the ability to read information about the operating system environment of the user or system accessing this application.";
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null, IShellContext? context = null)
    {
        if ( parameters is not null && parameters.Count > 0 )
        {
            throw new ArgumentException($"This parameter does not accept parameters, but {parameters.Count} parameters were specified");
        }

        var targetContext = context;

        if ( targetContext is null )
        {
            var newContext = new ShellContext();
            newContext.Initialize();
            targetContext = newContext;
        }

        if ( this.nativeInstance is null )
        {
            this.nativeInstance = new LocalContextNativePlugin(targetContext);
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}
