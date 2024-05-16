//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.CommandLine;
using Modulus.ChatGPS.Models;

const string DEBUG_FILE_NAME = "AIProxyLog.txt";

Dictionary<string,ServiceBuilder.ServiceId> validServices = new Dictionary<string, ServiceBuilder.ServiceId>() {
    { "AzureOpenAi", ServiceBuilder.ServiceId.AzureOpenAi }
};

var serviceIdOption = new Option<string>
    (name: "--serviceid",
     getDefaultValue: () => ServiceBuilder.ServiceId.AzureOpenAi.ToString())
    .FromAmong(ServiceBuilder.ServiceId.AzureOpenAi.ToString());

var whatIfOption = new Option<bool>
    (name: "--whatif");

var noEncodedArgumentsOption = new Option<bool>
    (name: "--no-encodedarguments");

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
thisCommand.Add(whatIfOption);
thisCommand.Add(noEncodedArgumentsOption);
thisCommand.Add(timeoutOption);
thisCommand.Add(debugOption);
thisCommand.Add(logFileOption);

thisCommand.SetHandler((serviceId, whatIf, noEncodedArguments, timeout, enableDebugOutput, logFilePath) =>
    {
    Start(serviceId, whatIf, noEncodedArguments, timeout, enableDebugOutput, logFilePath);
    },
    serviceIdOption, whatIfOption, noEncodedArgumentsOption, timeoutOption, debugOption, logFileOption);

thisCommand.Invoke(args);

void Start( string serviceId, bool whatIf, bool noEncodedArguments, int timeout, bool enableDebugOutput, string? logFilePath )
{
    // Parameter is null if you specify it with no value, but if you don't specify it
    // at all, it gets the default value of "" that we configured above
    var targetLogFilePath = logFilePath is null ?
        DEBUG_FILE_NAME :
        ( logFilePath.Length > 0 ? logFilePath : null );

    var logLevel = ( ( targetLogFilePath is not null ) || enableDebugOutput ) ?
        Logger.LogLevel.Debug : Logger.LogLevel.Default;

    System.Diagnostics.Debugger.Break();

    try
    {
        Logger.InitializeDefaultLogger( logLevel, enableDebugOutput, targetLogFilePath);

        Logger.Log(string.Format("Started AIProxy in process {0} -- debug output enabled", System.Diagnostics.Process.GetCurrentProcess().Id));

        var proxyApp = new ProxyApp(validServices[serviceId], whatIf, ! noEncodedArguments, timeout);

        proxyApp.Run();

        Logger.Log("Exiting AIProxy");
    }
    finally
    {
        Logger.End();
    }
}

