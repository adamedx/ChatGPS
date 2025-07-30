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

using Modulus.ChatGPS.Logging;

internal class Logger
{
    static internal void InitializeDefaultLogger( LogLevel logLevel = LogLevel.Default, bool consoleOutput = false, string? logFilePath = null )
    {
        if ( Logger.defaultLogger is not null )
        {
            throw new InvalidOperationException("The logger has already been initialized.");
        }

        Logger.defaultLogger = new Logger( logLevel, consoleOutput, logFilePath );

        Logger.defaultLogger.Open();
    }

    internal Logger( LogLevel logLevel = LogLevel.Default, bool consoleOutput = false, string? logFilePath = null )
    {
        // SimpleLogger is actually used within OpenTelemetryLogger
        // this.logger = new SimpleLogger(logLevel, consoleOutput, logFilePath);
        var openTelemetryLogger = new OpenTelemetryLogger(logLevel, consoleOutput, logFilePath);
        this.logger = openTelemetryLogger;
        this.loggerFactory = openTelemetryLogger.LoggerFactory;
    }

    internal void Open()
    {
        this.logger.Open();
    }

    internal void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        this.logger.Write( outputString, logLevel);
    }

    internal void Close()
    {
        this.logger.Close();
    }

    internal void Flush()
    {
        this.logger.Flush();
    }

    internal Microsoft.Extensions.Logging.ILoggerFactory? LoggerFactory
    {
        get
        {
            return this.loggerFactory;
        }
    }

    internal static Logger DefaultLogger
    {
        get
        {
            return Logger.defaultLogger;
        }
    }

    internal static void Log( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Write( outputString, logLevel );
    }

    internal static void FlushLog()
    {
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Flush();
    }

    internal static void End()
    {
        if ( Logger.defaultLogger is not null )
        {
            Logger.defaultLogger.Close();
        }
    }

    private static Logger? defaultLogger;
    private IProxyLogger logger;
    private Microsoft.Extensions.Logging.ILoggerFactory loggerFactory;
}

