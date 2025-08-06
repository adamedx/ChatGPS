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

using Modulus.ChatGPS.Logging;

public class Logger
{
    static public void InitializeDefaultLogger( Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory )
    {
        if ( Logger.defaultLogger is not null )
        {
            throw new InvalidOperationException("The logger has already been initialized.");
        }

        Logger.defaultLogger = new Logger( loggerFactory );

        Logger.defaultLogger.Open();
    }

    public Logger( Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory = null )
    {
        this.loggerFactory = loggerFactory;
        this.logWriter = new NativeLogger(loggerFactory);
    }

    public void Open()
    {
        this.logWriter.Open();
    }

    public void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        this.logWriter.Write( outputString, logLevel);
    }

    public void Close()
    {
        this.logWriter.Close();
    }

    public void Flush()
    {
        this.logWriter.Flush();
    }

    public static Logger DefaultLogger
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

    public static void Log( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Write( outputString, logLevel );
    }

    public static void FlushLog()
    {
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Flush();
    }

    public static void End()
    {
        if ( Logger.defaultLogger is not null )
        {
            Logger.defaultLogger.Close();
        }
    }

    public static Microsoft.Extensions.Logging.ILoggerFactory? LoggerFactory
    {
        get => Logger.DefaultLogger.loggerFactory;
    }

    private static Logger? defaultLogger;
    private ILogWriter logWriter;
    private Microsoft.Extensions.Logging.ILoggerFactory? loggerFactory;
}

