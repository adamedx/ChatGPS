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

using System.IO;

namespace Modulus.ChatGPS.Logging;

public class SimpleLogger : IProxyLogger
{
    internal SimpleLogger( LogLevel logLevel = LogLevel.Default, bool consoleOutput = false, bool rawOutput = false, string? logFilePath = null, object? syncObject = null )
    {
        this.syncObject = syncObject ?? this;
        this.rawOutput = rawOutput;
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

    public void Open()
    {
        if ( this.started )
        {
            throw new InvalidOperationException("The log must be started before the Write method may be executed");
        }

        if ( ( this.logFilePath is not null ) && ( this.logLevel != LogLevel.None ) )
        {
            var options = new FileStreamOptions() {
                Mode = FileMode.Append,
                Access = FileAccess.Write,
                Share = FileShare.ReadWrite
            };

            this.fileWriter = new StreamWriter(this.logFilePath, options);
            this.fileWriter.AutoFlush = true;
        }

        this.started = true;
    }

    public void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        if ( this.logLevel >= logLevel )
        {
            var entryWithTime = SimpleLogger.GetFriendlyLogLine(outputString);
            var logLine = this.rawOutput ? outputString + "\n" : entryWithTime;

            lock ( this.syncObject )
            {
                if ( this.fileWriter is not null )
                {
                    this.fileWriter.Write(logLine);
                }
            }

            if ( this.consoleOutput )
            {
                // The '.' at the start is a signal to automated consumers of the console output stream to ignore this
                // line as debug output
                Console.Write($".{logLine}");
            }
        }
    }

    public void Close()
    {
        lock ( this.syncObject )
        {
            if ( this.ended )
            {
                throw new InvalidOperationException("The Close method may not be invoked more than once");
            }

            if ( this.fileWriter is not null )
            {
                this.fileWriter.Close();
            }

            this.ended = true;
        }
    }

    public void Flush()
    {
        lock ( this.syncObject )
        {
            if ( this.fileWriter is not null )
            {
                this.fileWriter.Flush();
            }
        }
    }

    internal static string GetFriendlyLogLine(string outputString)
    {
        var managedThreadId = System.Threading.Thread.CurrentThread.ManagedThreadId;

        return string.Format("{0}\t0x{1:X8}\t{2}\n", DateTimeOffset.Now.LocalDateTime.ToString("u"), managedThreadId, outputString);
    }

    private LogLevel logLevel;
    private bool consoleOutput;
    private bool rawOutput;
    private string? logFilePath;
    private object syncObject;
    private StreamWriter? fileWriter;
    private bool started;
    private bool ended;
}
