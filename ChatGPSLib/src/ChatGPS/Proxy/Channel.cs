//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.IO;
using Modulus.ChatGPS.OS;

namespace Modulus.ChatGPS.Proxy;

public class Channel : IChannel
{
    public Channel(string proxyHostPath, int idleTimeoutMs = 60000, string? logFilePath = null, string? logLevel = null)
    {
        this.proxyHostPath = proxyHostPath;
        this.logFilePath = logFilePath;
        this.logLevel = logLevel;
        this.idleTimeoutMs = idleTimeoutMs;
    }

    public async Task SendMessageAsync(string message)
    {
        InitializeChannel();

        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        await this.process.WriteLineAsync(message);

        return;
    }

    public void SetProxyHostPath(string proxyHostPathValue)
    {
        if ( this.proxyHostPath != null )
        {
            throw new InvalidOperationException("The proxy host path is already set and may not be set again.");
        }

        this.proxyHostPath = proxyHostPathValue;
    }

    public async Task<string?> ReadMessageAsync()
    {
        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        return await this.process.ReadLineAsync();
    }

    public void Reset()
    {
        if ( ( this.process is not null ) && ! this.process.HasExited )
        {
            this.process.Stop();
        }

        this.process = null;
    }

    void InitializeChannel(bool forceReset = false)
    {
        if ( forceReset )
        {
            this.Reset();
        }

        if ( this.process is null || this.process.HasExited )
        {
            if ( this.proxyHostPath is null )
            {
                throw new InvalidOperationException("The proxy host path has not been set; it must be set before a channel can be initialized");
            }

            var logFilePathArgument = this.logFilePath is not null ? $"--logfile {this.logFilePath} " : "";
            var logLevelArgument = this.logLevel is not null ? $"--debuglevel {this.logLevel} " : "";

            this.process = new Process(this.proxyHostPath, $"--timeout {this.idleTimeoutMs} {logLevelArgument}{logFilePathArgument}".Trim());
        }

        this.process.Start();
    }

    Process? process;
    string proxyHostPath;
    string? logFilePath;
    string? logLevel;
    int idleTimeoutMs;
}
