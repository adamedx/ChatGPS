//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

public class ServiceBuilder
{
    public enum ServiceId
    {
        AzureOpenAi
    }

    public static ServiceBuilder CreateBuilder()
    {
        return new ServiceBuilder();
    }

    public IChatService Build()
    {
        if ( this.serviceId is null )
        {
            throw new ArgumentException("A service identifier must be specified to build a service");
        }

        if ( this.options is null )
        {
            throw new ArgumentException("No service configuration options were specified");
        }

        IChatService newService;

        switch ( this.serviceId )
        {
            case ServiceId.AzureOpenAi:
                newService = new OpenAIChatService( this.options );
                break;
            default:
                throw new NotImplementedException($"Support for the specified service id {serviceId} is not yet implemented");
        }

        return newService;
    }

    public ServiceBuilder WithServiceId( ServiceId serviceId )
    {
        if ( this.serviceId is not null )
        {
            throw new ArgumentException("A service identifier has already been specified for this service");
        }

        this.serviceId = serviceId;

        return this;
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

    private ServiceId? serviceId;
    private AiOptions? options;
}
