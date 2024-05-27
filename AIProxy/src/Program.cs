//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.CommandLine;
using Modulus.ChatGPS.Models;

const string DEBUG_FILE_NAME = "AIProxyLog.txt";

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

thisCommand.Add(whatIfOption);
thisCommand.Add(noEncodedArgumentsOption);
thisCommand.Add(timeoutOption);
thisCommand.Add(debugOption);
thisCommand.Add(logFileOption);

thisCommand.SetHandler((whatIf, noEncodedArguments, timeout, enableDebugOutput, logFilePath) =>
    {
    Start(whatIf, noEncodedArguments, timeout, enableDebugOutput, logFilePath);
    },
    whatIfOption, noEncodedArgumentsOption, timeoutOption, debugOption, logFileOption);

thisCommand.Invoke(args);

void Start( bool whatIf, bool noEncodedArguments, int timeout, bool enableDebugOutput, string? logFilePath )
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

        var proxyApp = new ProxyApp(timeout, whatIf);

        proxyApp.Run();

        Logger.Log(string.Format("Exiting AIProxy process {0}", System.Diagnostics.Process.GetCurrentProcess().Id));
    }
    finally
    {
        Logger.End();
    }
}

