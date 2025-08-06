//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.CommandLine;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Logs;

using Modulus.ChatGPS.Logging;
using Modulus.ChatGPS.Models;

const string DEBUG_FILE_NAME = "AIProxyLog.txt";

var whatIfOption = new Option<bool>
    (name: "--whatif");

var timeoutOption = new Option<int>
    (name: "--timeout",
     getDefaultValue: () => 10000);

var debugOption = new Option<bool>
    (name: "--debug");

var debugLevelOption = new Option<LogLevel>
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

void Start( bool whatIf, int timeout, bool enableDebugOutput, LogLevel debugLevel = LogLevel.None, string? logFilePath = null )
{
    // Parameter is null if you specify it with no value, but if you don't specify it
    // at all, it gets the default value of "" that we configured above
    var targetLogFilePath = logFilePath is null ?
        DEBUG_FILE_NAME :
        ( logFilePath.Length > 0 ? logFilePath : null );

    var logLevel = ( ( targetLogFilePath is not null ) || enableDebugOutput ) ?
        debugLevel : LogLevel.None;

    var builder = Host.CreateApplicationBuilder();

    builder.Logging.ClearProviders();
    builder.Logging.SetMinimumLevel(logLevel);
    builder.Logging.AddOpenTelemetry( options =>
    {
        options.AddProcessor(new Modulus.ChatGPS.Logging.LogRecordExtensionProcessor());

        if ( targetLogFilePath is not null )
        {
            options.AddProcessor(new SimpleLogRecordExportProcessor( new Modulus.ChatGPS.Logging.FileTraceExporter( targetLogFilePath, enableDebugOutput, builder ) ));
        }
    });

    builder.Services.AddSingleton<IAIProxyService, ProxyApp>();

    using var host = builder.Build();

    RunProxy(host, timeout, whatIf, logLevel);
}

void RunProxy(IHost host, int timeout, bool whatIf, LogLevel logLevel)
{
    var proxyApp = host.Services.GetRequiredService<IAIProxyService>();

    var loggerFactory = host.Services.GetRequiredService<ILoggerFactory>();

    Logger.InitializeDefaultLogger( loggerFactory );

    Logger.Log(string.Format("Started AIProxy in process {0} -- debug loglevel: {1}", System.Diagnostics.Process.GetCurrentProcess().Id, logLevel));
    Logger.Log(string.Format("Process arguments: {0}", System.Environment.CommandLine));

    var hostExecution = host.RunAsync();

    try
    {
        proxyApp.Run(timeout, whatIf);

        Logger.Log(string.Format("Exiting AIProxy process {0} normally.", System.Diagnostics.Process.GetCurrentProcess().Id));
    }
    catch
    {
        Logger.Log(string.Format("*****Abornmal exit for AIProxy process {0}.", System.Diagnostics.Process.GetCurrentProcess().Id));
        throw;
    }
    finally
    {
        Logger.End();
    }
}
