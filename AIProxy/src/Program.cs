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

var timeoutOption = new Option<int>
    (name: "--timeout",
     getDefaultValue: () => 10000);

var debugOption = new Option<bool>
    (name: "--debug");

var debugLevelOption = new Option<Logger.LogLevel>
    (name: "--debuglevel") { Arity = ArgumentArity.ZeroOrOne };;

var logFileOption = new Option<string>
    (name: "--logfile",
     getDefaultValue: () => "" ) { Arity = ArgumentArity.ZeroOrOne };

var thisCommand = new RootCommand("AI service proxy application");

thisCommand.Add(whatIfOption);
thisCommand.Add(timeoutOption);
thisCommand.Add(debugOption);
thisCommand.Add(debugLevelOption);
thisCommand.Add(logFileOption);

thisCommand.SetHandler((whatIf, timeout, enableDebugOutput, debugLevel, logFilePath) =>
    {
    Start(whatIf, timeout, enableDebugOutput, debugLevel, logFilePath);
    },
    whatIfOption, timeoutOption, debugOption, debugLevelOption, logFileOption);

thisCommand.Invoke(args);

void Start( bool whatIf, int timeout, bool enableDebugOutput, Logger.LogLevel debugLevel = Logger.LogLevel.Debug, string? logFilePath = null )
{
    // Parameter is null if you specify it with no value, but if you don't specify it
    // at all, it gets the default value of "" that we configured above
    var targetLogFilePath = logFilePath is null ?
        DEBUG_FILE_NAME :
        ( logFilePath.Length > 0 ? logFilePath : null );

    var logLevel = ( ( targetLogFilePath is not null ) || enableDebugOutput ) ?
        debugLevel : Logger.LogLevel.Default;

    System.Diagnostics.Debugger.Break();

    try
    {
        Logger.InitializeDefaultLogger( logLevel, enableDebugOutput, targetLogFilePath);

        Logger.Log(string.Format("Started AIProxy in process {0} -- debug loglevel: {1}", System.Diagnostics.Process.GetCurrentProcess().Id, logLevel));
        Logger.Log(string.Format("Process arguments: {0}", System.Environment.CommandLine));

        var proxyApp = new ProxyApp(timeout, whatIf);

        proxyApp.Run();

        Logger.Log(string.Format("Exiting AIProxy process {0}", System.Diagnostics.Process.GetCurrentProcess().Id));
    }
    finally
    {
        Logger.End();
    }
}

