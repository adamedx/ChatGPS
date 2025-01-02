//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
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
    LocalOnnx
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
        this.TokenLimit = options.TokenLimit;
        this.OutputType = options.OutputType;
        this.SigninInteractionAllowed = options.SigninInteractionAllowed;
    }

    public string? Provider {get; set;}
    public Uri? ApiEndpoint { get; set; }
    public string? LocalModelPath { get; set; }
    public string? ModelIdentifier { get; set; }
    public string? DeploymentName { get; set; }
    public int? TokenLimit { get; set; }
    public bool? SigninInteractionAllowed { get; set; }

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
