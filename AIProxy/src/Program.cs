//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.CommandLine;
using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Models;

const string AI_SERVICE_KEY_ENVIRONMENT_VARIABLE = "__AIPROXY_KEY";
const string DEBUG_FILE_NAME = "AIProxyLog.txt";

Dictionary<string,ServiceBuilder.ServiceId> validServices = new Dictionary<string, ServiceBuilder.ServiceId>() {
    { "AzureOpenAi", ServiceBuilder.ServiceId.AzureOpenAi }
};

var serviceIdOption = new Option<string>
    (name: "--serviceid",
     getDefaultValue: () => ServiceBuilder.ServiceId.AzureOpenAi.ToString())
    .FromAmong(ServiceBuilder.ServiceId.AzureOpenAi.ToString());

var configOption = new Option<string>
    (name: "--config") { IsRequired = true };

var timeoutOption = new Option<int>
    (name: "--timeout",
     getDefaultValue: () => 10000);

var debugOption = new Option<bool>
    (name: "--debug");

var logFileOption = new Option<string>
    (name: "--logfile",
     getDefaultValue: () => "" ) { Arity = ArgumentArity.ZeroOrOne };

var thisCommand = new RootCommand("AI service proxy application");

thisCommand.Add(serviceIdOption);
thisCommand.Add(configOption);
thisCommand.Add(timeoutOption);
thisCommand.Add(debugOption);
thisCommand.Add(logFileOption);

thisCommand.SetHandler((serviceId, config, timeout, enableDebugOutput, logFilePath) =>
    {
        Start(serviceId, config, timeout, enableDebugOutput, logFilePath);
    },
    serviceIdOption, configOption, timeoutOption, debugOption, logFileOption);

thisCommand.Invoke(args);

void Start( string serviceId, string config, int timeout, bool enableDebugOutput, string? logFilePath )
{
    var serializedCommandArguments = config;

    // Parameter is null if you specify it with no value, but if you don't specify it
    // at all, it gets the default value of "" that we configured above
    var targetLogFilePath = logFilePath is null ?
        DEBUG_FILE_NAME :
        ( logFilePath.Length > 0 ? logFilePath : null );

    var logLevel = ( ( targetLogFilePath is not null ) || enableDebugOutput ) ?
        Logger.LogLevel.Debug : Logger.LogLevel.Default;

    try
    {
        Logger.InitializeDefaultLogger( logLevel, enableDebugOutput, targetLogFilePath);

        Logger.Log("Started AIProxy in process {0} -- debug output enabled", System.Diagnostics.Process.GetCurrentProcess().Id);

        var configuration = GetConfiguration( serializedCommandArguments );

        var proxyApp = new ProxyApp(validServices[serviceId], configuration, timeout);

        proxyApp.Run();

        Logger.Log("Exiting AIProxy");
    }
    finally
    {
        Logger.End();
    }
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

