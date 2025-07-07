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
using Microsoft.SemanticKernel.Plugins.Web;

namespace Modulus.ChatGPS.Plugins;

public class WebDownloadPluginProvider : PluginProvider
{
    internal WebDownloadPluginProvider() : base("WebDownloadPlugin")
    {
        this.Description = "Enables the ability to download internet content to the local file system";
        AddPluginParameter("allowedFolders", "Allosed destination directories for downloaded content", true);
        AddPluginParameter("allowedDomains", "Allowed domains of hosts from which to download content", true);
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null)
    {
        if ( parameters is null || parameters.Count < 2 )
        {
            throw new ArgumentException("Invalid parameters specified -- the allowedFolders and allowedDomains parameters must be specified");
        }

        if ( this.nativeInstance is null )
        {
            #pragma warning disable SKEXP0050

            if ( parameters is null )
            {
                throw new ArgumentException("Invalid parameters specified -- the allowedFolders and allowedDomains parameters must be specified");
            }

            var allowedFoldersResult = (object[]?) GetPluginParameter("allowedFolders", parameters);
            var allowedDomainsResult = (object[]?) GetPluginParameter("allowedDomains", parameters);

            if ( allowedFoldersResult is null || allowedDomainsResult is null )
            {
                throw new ArgumentException("Both the allowedFolders and allowedDomains parameters must be specified.");
            }

            // TODO: All of this is a terrible workaround -- it seems that the PluginParameterValue type is getting
            // System.Object[] as the type for arrays, possibly due to PowerShell type coercion. We'll let this remain for the
            // sake of compilation, but this type is not usable until these issues are resolved.
            string[] allowedFolders = new string[allowedFoldersResult.Length];
            string[] allowedDomains = new string[allowedDomainsResult.Length];

            for ( var folderIndex = 0; folderIndex < allowedFoldersResult.Length; folderIndex++ )
            {
                var folderValue = allowedFoldersResult[folderIndex].ToString();

                if ( folderValue is null )
                {
                    throw new ArgumentException("The specified parameter value is null");
                }

                allowedFolders[folderIndex] = folderValue;
            }

            for ( var domainIndex = 0; domainIndex < allowedDomainsResult.Length; domainIndex++ )
            {
                var domainValue = allowedDomainsResult[domainIndex].ToString();

                if ( domainValue is null )
                {
                    throw new ArgumentException("The specified parameter value is null");
                }

                allowedDomains[domainIndex] = domainValue;
            }

            this.nativeInstance = new WebFileDownloadPlugin(null);

            this.nativeInstance.AllowedFolders = allowedFolders;
            this.nativeInstance.AllowedDomains = allowedDomains;

            #pragma warning restore SKEXP0050
        }

        return this.nativeInstance;
    }
    #pragma warning disable SKEXP0050

    private WebFileDownloadPlugin? nativeInstance;

    #pragma warning restore SKEXP0050
}
