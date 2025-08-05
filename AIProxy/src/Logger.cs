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
    static internal void InitializeDefaultLogger( Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory )
    {
        if ( Logger.defaultLogger is not null )
        {
            throw new InvalidOperationException("The logger has already been initialized.");
        }

        Logger.defaultLogger = new Logger( loggerFactory );

        Logger.defaultLogger.Open();
    }

    internal Logger( Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory = null )
    {
        this.loggerFactory = loggerFactory;
        this.logger = new NativeLogger(loggerFactory);
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

    internal static Logger DefaultLogger
    {
        get
        {
            if ( Logger.defaultLogger is null )
            {
                throw new InvalidOperationException("An attempt was made to access logging before logging was initialized");
            }

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

    internal static Microsoft.Extensions.Logging.ILoggerFactory? LoggerFactory
    {
        get => Logger.DefaultLogger.loggerFactory;
    }

    private static Logger? defaultLogger;
    private IProxyLogger logger;
    private Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory;
}

