//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

internal class Logger
{
    internal enum LogLevel
    {
        Default,
        None,
        Debug
    }

    static internal void InitializeDefaultLogger( LogLevel logLevel = LogLevel.Default )
    {
        if ( Logger.defaultLogger is not null )
        {
            throw new InvalidOperationException("The logger has already been initialized.");
        }

        Logger.defaultLogger = new Logger( logLevel );
    }

    internal Logger( LogLevel logLevel = LogLevel.Default )
    {
        if ( logLevel == LogLevel.Default )
        {
            this.logLevel = LogLevel.None;
        }
        else
        {
            this.logLevel = logLevel;
        }
    }

    internal void Write( string format, params object[] logArguments )
    {
        if ( this.logLevel == LogLevel.Debug )
        {
            var managedThreadId = System.Threading.Thread.CurrentThread.ManagedThreadId;

            var entryWithTime = string.Format("{0}\t0x{1:X8}\t{2}", DateTimeOffset.Now.LocalDateTime.ToString("u"), managedThreadId, format);
            Console.WriteLine( entryWithTime,  logArguments );
        }
    }

    internal static void Log( string format, params object[] logArguments )
    {
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Write( format, logArguments );
    }

    private static Logger? defaultLogger;
    private LogLevel logLevel;
}
