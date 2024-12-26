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
        if ( this.options is null )
        {
            throw new ArgumentException("No service configuration options were specified");
        }

        IChatService newService;

        switch ( this.options.Provider )
        {
            case ModelProvider.AzureOpenAI:
                newService = new OpenAIChatService( this.options );
                break;
            case ModelProvider.LocalOnnx:
                newService = new LocalAIChatService( this.options );
                break;
            default:
                throw new NotImplementedException($"Support for the model provider id {options.Provider} is not yet implemented");
        }

        return newService;
    }

    public ServiceBuilder WithOptions( AiOptions options )
    {
        if ( this.options is not null )
        {
            throw new ArgumentException("Optoins have already been specified for this service");
        }

        this.options = options;

        return this;
    }

    private ServiceBuilder() {}

    private AiOptions? options;
}
