//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//


using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

const string AI_SERVICE_KEY_ENVIRONMENT_VARIABLE = "__AIPROXY_KEY";

Start(args);

void Start( string[] args )
{
    bool enableDebugOutput;
    ServiceBuilder.ServiceId serviceId;

    var serializedCommandArguments = GetCommandArguments( args, out enableDebugOutput, out serviceId );

    Logger.InitializeDefaultLogger( enableDebugOutput ? Logger.LogLevel.Debug : Logger.LogLevel.Default );

    Logger.Log("Started AIProxy in process {0} -- debug output enabled", System.Diagnostics.Process.GetCurrentProcess().Id);

    var configuration = GetConfiguration( serializedCommandArguments );

    var service = GetAiService( serviceId, configuration );

    var listener = new Modulus.ChatGPS.AIProxy.Listener(Responder);

    CancellationTokenSource cancellationSource = new CancellationTokenSource();

    try
    {
        listener.Start( cancellationSource );

        listener.Wait(6000);

        listener.Stop();
    }
    finally
    {
        cancellationSource.Dispose();
    }

    Logger.Log("Exiting AIProxy");
}

string GetCommandArguments(string[] commandArguments, out bool enableDebugOutput, out ServiceBuilder.ServiceId serviceId)
{
    if ( commandArguments.Length < 2 )
    {
        throw new ArgumentException("Usage:\n\tAIProxy <json-string-argument> [--debug]\n\n\tMissing mandatory JSON configuration string argument");
    }
    else if ( commandArguments.Length > 2 && commandArguments[2] != "--debug" )
    {
        throw new ArgumentException("Usage:\n\tAIProxy <json-string-argument> [--debug]\n\n\tInvalid number or type of arguments");
    }

    if ( commandArguments[0] == ServiceBuilder.ServiceId.AzureOpenAi.ToString() )
    {
        serviceId = ServiceBuilder.ServiceId.AzureOpenAi;
    }
    else
    {
        throw new ArgumentException($"The specified service id '{args[0]}' is not a valid service identiier");
    }

    enableDebugOutput = false;

    if ( commandArguments.Length > 2 )
    {
        enableDebugOutput = true;
    }

    return commandArguments[1];
}

AiOptions GetConfiguration( string serializedConfiguration )
{
    Logger.Log("Reading and validating configuration");

    JsonNode? jsonNode = null;

    try
    {
        jsonNode = JsonNode.Parse( serializedConfiguration );
    }
    catch ( Exception e )
    {
        throw new ArgumentException( "The specified configuration was not valid JSON", e );
    }

    AiOptions? configuration = JsonSerializer.Deserialize<AiOptions>( jsonNode );

    if ( configuration is null )
    {
        throw new ArgumentException("The specified configuration JSON did not conform to a valid schema.");
    }

    if ( configuration.ApiKey is not null )
    {
        throw new ArgumentException($"The ApiKey property must not be specified as configuration in the command-line because it is a sensitive value. Instead, it may be specified using the '{AI_SERVICE_KEY_ENVIRONMENT_VARIABLE}' environment variable.");
    }

    var apiKeyEnvironmentVariableValue = System.Environment.GetEnvironmentVariable(AI_SERVICE_KEY_ENVIRONMENT_VARIABLE);

    if ( apiKeyEnvironmentVariableValue is not null )
    {
        configuration.ApiKey = apiKeyEnvironmentVariableValue;
    }

    Logger.Log($"Environment variable {AI_SERVICE_KEY_ENVIRONMENT_VARIABLE} specified:{0}", ( apiKeyEnvironmentVariableValue is not null ).ToString() );

    Logger.Log("Successfully read valid configuration");

    return configuration;
}

IChatService GetAiService(ServiceBuilder.ServiceId serviceId, AiOptions options)
{
    Logger.Log($"Getting AI service with service id {serviceId}");

    var builder = ServiceBuilder.CreateBuilder();

    var service =  builder.WithServiceId(serviceId).WithOptions(options).Build();

    Logger.Log($"Successfully retrieved service");

    return service;
}

string? Responder(string input)
{
    return null;
}
