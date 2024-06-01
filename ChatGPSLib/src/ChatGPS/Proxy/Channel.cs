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
    private Channel(int idleTimeoutMs = 0, string? proxyHostPath = null, string? logLevel = null, string? logFilePath = null)
    {
        string? targetImagePath =
            proxyHostPath is not null ?
            proxyHostPath :
            Channel.defaultProxyPath;

        if ( targetImagePath is null )
        {
            throw new ArgumentException("The path for the proxy must not be null");
        }

        var targetLogFilePath =
            logFilePath is not null ?
            logFilePath :
            Channel.defaultLogFilePath;

        this.proxyHostPath = targetImagePath;
        this.logFilePath = targetLogFilePath;
        this.logLevel = logLevel ?? Channel.defaultLogLevel;
        this.idleTimeoutMs = idleTimeoutMs == 0 ? 60000 : idleTimeoutMs;
    }

    static internal Channel GetActiveChannel(int idleTimeoutMs = 0, string? proxyHostPath = null, string? logLevel = null, string? logFilePath = null, bool forceNewChannel = false)
    {
        if ( forceNewChannel || Channel.activeChannel is null )
        {
            Channel.activeChannel = new Channel(idleTimeoutMs, proxyHostPath, logLevel, logFilePath);
        }

        return Channel.activeChannel;
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

    internal static void SetDefaultLogLevel(string? logLevel)
    {
        Channel.defaultLogLevel = logLevel;
    }

    internal static void SetDefaultLogFilePath(string? defaultLogFilePath)
    {
        if ( defaultLogFilePath is not null )
        {
            Channel.defaultLogFilePath = defaultLogFilePath;
        }
    }

    internal static void SetDefaultProxyPath(string defaultProxyPath)
    {
        Channel.defaultProxyPath = defaultProxyPath;
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

    static string? defaultProxyPath;
    static string? defaultLogFilePath;
    static string? defaultLogLevel;
    static Channel? activeChannel;

    Process? process;
    string proxyHostPath;
    string? logFilePath;
    string? logLevel;
    int idleTimeoutMs;
}
