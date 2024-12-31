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
    }

    public string? Provider {get; set;}
    public Uri? ApiEndpoint { get; set; }
    public string? LocalModelPath { get; set; }
    public string? ModelIdentifier { get; set; }
    public string? DeploymentName { get; set; }
    public int? TokenLimit { get; set; }

    public string? OutputType {get; set;}
}

public sealed class AiOptions : AiProviderOptions
{
    public AiOptions() {}
    public AiOptions(AiProviderOptions sourceOptions) : base(sourceOptions) {}

    public string? ApiKey { get; set; }
}
