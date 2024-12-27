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

public sealed class AiOptions
{
    public AiOptions() { this.TokenLimit = 400; }

    public string? Provider {get; set;}
    public Uri? ApiEndpoint { get; set; }
    public string? LocalModelPath { get; set; }
    public string? ModelIdentifier { get; set; }
    public int? TokenLimit { get; set; }
    public string? ApiKey { get; set; }

    public string? OutputType {get; set;}
}
