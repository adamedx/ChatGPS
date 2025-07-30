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



using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Logs;

namespace Modulus.ChatGPS.Logging;

public class OpenTelemetryLogger : IProxyLogger
{
    public OpenTelemetryLogger(LogLevel logLevel = LogLevel.Default, bool consoleOutput = false, string? logFilePath = null)
    {
        this.logLevel = logLevel;
        this.loggerFactory = Microsoft.Extensions.Logging.LoggerFactory.Create(builder =>
        {
            builder.SetMinimumLevel(OpenTelemetryLogger.ToStandardLogLevel(logLevel));
            builder.AddOpenTelemetry( options =>
            {
                options.AddProcessor(new LogRecordExtensionProcessor());

                if ( logFilePath is not null )
                {
                    options.AddProcessor(new SimpleLogRecordExportProcessor( new FileTraceExporter( logLevel, logFilePath, consoleOutput, this ) ));
                }
            });
        });
    }

    public void Open()
    {
        if ( logger is not null )
        {
            throw new InvalidOperationException("The logger is already open");
        }

        this.logger = loggerFactory.CreateLogger("Modulus.ChatGPS.AIProxy");
    }

    public void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        if ( this.logger is null )
        {
            throw new InvalidOperationException("The logger has not been opened.");
        }

        var standardLogLevel = OpenTelemetryLogger.ToStandardLogLevel(logLevel);

        this.logger.Log(standardLogLevel, outputString);
    }

    public void Close()
    {
        this.loggerFactory.Dispose();
    }

    public void Flush()
    {
    }

    public ILoggerFactory LoggerFactory
    {
        get
        {
            return this.loggerFactory;
        }
    }

    private static Microsoft.Extensions.Logging.LogLevel ToStandardLogLevel(LogLevel logLevel)
    {
        var standardLogLevel = logLevel switch
        {
            LogLevel.Default => Microsoft.Extensions.Logging.LogLevel.Debug,
            LogLevel.None => Microsoft.Extensions.Logging.LogLevel.None,
            LogLevel.Error => Microsoft.Extensions.Logging.LogLevel.Error,
            LogLevel.Warning => Microsoft.Extensions.Logging.LogLevel.Warning,
            LogLevel.Debug => Microsoft.Extensions.Logging.LogLevel.Debug,
            LogLevel.DebugVerbose => Microsoft.Extensions.Logging.LogLevel.Trace,
            _ => Microsoft.Extensions.Logging.LogLevel.None
        };

        return standardLogLevel;
    }

    private LogLevel logLevel = LogLevel.None;
    Microsoft.Extensions.Logging.ILogger? logger;
    ILoggerFactory loggerFactory;
}

