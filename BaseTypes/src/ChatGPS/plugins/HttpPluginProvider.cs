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

public sealed class HttpPluginProvider : PluginProvider
{
    public HttpPluginProvider() : base("HttpPlugin", "Enables the local computer to access local and remote resources via http protocol requests.")
    {
        AddPluginParameter("allowedDomains", "Comma-separated list of domains (and their subdomains) that requests may be made to; when specified, requests to any other domain are blocked.");
        AddPluginParameter("disallowedDomains", "Comma-separated list of domains (and their subdomains) that requests may not be made to.");
        AddPluginParameter("allowRedirect", "Set to $true to allow HTTP requests to follow redirects; by default, redirects are not followed and an error is raised if a redirect response is received.");
    }

    public override object GetNativeInstance(Dictionary<string, PluginParameterValue>? parameters = null, IShellContext? context = null)
    {
        if ( this.nativeInstance is null )
        {
            var allowedDomains = HttpNativePlugin.ParseDomains((string?) GetPluginParameter("allowedDomains", parameters));
            var disallowedDomains = HttpNativePlugin.ParseDomains((string?) GetPluginParameter("disallowedDomains", parameters));
            var allowRedirectRaw = GetPluginParameter("allowRedirect", parameters);
            var allowRedirect = allowRedirectRaw switch
            {
                null => false,
                bool b => b,
                string s => bool.Parse(s),
                _ => throw new ArgumentException($"The parameter 'allowRedirect' must be a boolean value; the value of type {allowRedirectRaw.GetType().Name} is not supported.")
            };

            this.nativeInstance = new HttpNativePlugin(allowedDomains, disallowedDomains, allowRedirect);
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}
