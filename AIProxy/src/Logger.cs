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
        Error,
        Debug,
        DebugVerbose
    }

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
        this.consoleOutput = consoleOutput;
        this.logFilePath = logFilePath;

        if ( logLevel == LogLevel.Default )
        {
            this.logLevel = LogLevel.None;
        }
        else
        {
            this.logLevel = logLevel;
        }
    }

    internal void Open()
    {
        if ( this.started )
        {
            throw new InvalidOperationException("The log must be started before the Write method may be executed");
        }

        if ( ( this.logFilePath is not null ) && ( this.logLevel != LogLevel.None ) )
        {
            var options = new FileStreamOptions() {
                Mode = FileMode.Append,
                Access = FileAccess.Write
            };

            this.fileWriter = new StreamWriter(this.logFilePath, options);
        }

        this.started = true;
    }

    internal void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        if ( this.logLevel >= logLevel )
        {
            var managedThreadId = System.Threading.Thread.CurrentThread.ManagedThreadId;

            var entryWithTime = string.Format("{0}\t0x{1:X8}\t{2}\n", DateTimeOffset.Now.LocalDateTime.ToString("u"), managedThreadId, outputString);

            lock (this )
            {
                if ( this.fileWriter is not null )
                {
                    this.fileWriter.Write(entryWithTime);
                }
            }

            if ( this.consoleOutput )
            {
                // The '.' at the start is a signal to automated consumers of the console output stream to ignore this
                // line as debug output
                Console.Write($".{entryWithTime}");
            }
        }
    }

    internal void Close()
    {
        if ( this.ended )
        {
            throw new InvalidOperationException("The End method may not be invoked more than once");
        }

        lock (this )
        {
            if ( this.fileWriter is not null )
            {
                this.fileWriter.Close();
            }
        }

        this.ended = true;
    }

    internal void Flush()
    {
        lock (this )
        {
            if ( this.fileWriter is not null )
            {
                this.fileWriter.Flush();
            }
        }
    }


    internal static void Log( string outputString, LogLevel logLevel = Logger.LogLevel.Debug )
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
        if ( Logger.defaultLogger is null )
        {
            throw new InvalidOperationException("The type has not been initialized");
        }

        Logger.defaultLogger.Close();
    }

    private static Logger? defaultLogger;
    private LogLevel logLevel;
    private bool consoleOutput;
    private string? logFilePath;
    private StreamWriter? fileWriter;
    private bool started;
    private bool ended;
}
