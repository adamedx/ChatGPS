//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

public class ServiceBuilder
{
    public static ServiceBuilder CreateBuilder()
    {
        return new ServiceBuilder();
    }

    public IChatService Build()
    {
        ModelProvider provider;

        if ( this.options is null )
        {
            throw new ArgumentException("No service configuration options were specified");
        }
        else if ( this.options.Provider is not null )
        {
            if ( ! ModelProvider.TryParse(this.options.Provider, out provider) )
            {
                provider = ModelProvider.Unspecified;
            }
        }
        else
        {
            provider = ModelProvider.Unspecified;
        }

        IChatService newService;

        switch ( provider )
        {
            case ModelProvider.AzureOpenAI:
                newService = new AzureOpenAIChatService( this.options, this.userAgent );
                break;
            case ModelProvider.OpenAI:
                newService = new OpenAIChatService( this.options, this.userAgent );
                break;
            case ModelProvider.LocalOnnx:
                newService = new LocalAIChatService( this.options );
                break;
            case ModelProvider.Ollama:
                newService = new OllamaChatService( this.options );
                break;
            case ModelProvider.Google:
                newService = new GoogleChatService( this.options );
                break;
            default:
                throw new NotImplementedException($"Support for the model provider id '{options.Provider}' is not yet implemented");
        }

        return newService;
    }

    public ServiceBuilder WithOptions( AiOptions options )
    {
        if ( this.options is not null )
        {
            throw new ArgumentException("Options have already been specified for this service");
        }

        this.options = options;

        return this;
    }

    public ServiceBuilder WithUserAgent( string? userAgent )
    {
        if ( this.userAgent is not null )
        {
            throw new ArgumentException("A user agent has already been specified for this service");
        }

        this.userAgent = userAgent;

        return this;
    }

    private ServiceBuilder() {}

    private AiOptions? options;
    private string? userAgent;
}
