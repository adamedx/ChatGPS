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
    AzureOpenAI,
    LocalOnnx
}

public sealed class AiOptions
{
    public AiOptions() { this.TokenLimit = 400; }

    public ModelProvider? Provider {get; set;}
    public Uri? ApiEndpoint { get; set; }
    public string? LocalModelPath { get; set; }
    public string? ModelIdentifier { get; set; }
    public int? TokenLimit { get; set; }
    public string? ApiKey { get; set; }

    public OutputType? OutputType {get; set;}
}
