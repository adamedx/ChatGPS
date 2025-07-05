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

namespace Modulus.ChatGPS.Models;

public enum OutputType
{
    Raw,
    Normal
};

public enum ModelProvider
{
    Unspecified,
    AzureOpenAI,
    OpenAI,
    LocalOnnx,
    Ollama,
    Google
}

public class AiProviderOptions
{
    public AiProviderOptions() { this.TokenLimit = 400; }

    public AiProviderOptions( AiProviderOptions options )
    {
        this.Provider = options.Provider;
        this.ApiEndpoint = options.ApiEndpoint;
        this.LocalModelPath = options.LocalModelPath;
        this.ModelIdentifier = options.ModelIdentifier;
        this.DeploymentName = options.DeploymentName;
        this.ServiceIdentifier = options.ServiceIdentifier;
        this.TokenLimit = options.TokenLimit;
        this.OutputType = options.OutputType;
        this.SigninInteractionAllowed = options.SigninInteractionAllowed;
        this.PlainTextApiKey = options.PlainTextApiKey;
        this.AllowAgentAccess = options.AllowAgentAccess;
    }

    public string? Provider {get; set;}
    public Uri? ApiEndpoint { get; set; }
    public string? LocalModelPath { get; set; }
    public string? ModelIdentifier { get; set; }
    public string? DeploymentName { get; set; }
    public string? ServiceIdentifier { get; set; }
    public int? TokenLimit { get; set; }
    public bool? SigninInteractionAllowed { get; set; }
    public bool? PlainTextApiKey { get; set; }
    public bool? AllowAgentAccess { get; set; }

    public string? OutputType {get; set;}
}

public sealed class AiOptions : AiProviderOptions
{
    public AiOptions() {}
    public AiOptions(AiProviderOptions sourceOptions) : base(sourceOptions) {}

    public void Validate()
    {
        var hasLocal = this.LocalModelPath is not null && this.LocalModelPath.Length > 0;
        var hasRemote = this.ApiEndpoint is not null || ( this.ApiKey is not null && this.ApiKey.Length > 0 );

        if ( hasLocal )
        {
            if ( hasRemote )
            {
                throw new ArgumentException("The specified AI options are invalid; both a local and remote location may not be specified. Exactly one must be provided.");
            }
        }

        // Note that ApiKey will be empty in the case of a proxy service or delegated auth,
        // and some providers have an implicit API endpoint. So we can't assume a non-existent
        // local model path and lack of both ApiKey and ApiEndpoint as an impossibility for a remotely
        // hosted service.
    }

    public string? ApiKey { get; set; }
}

