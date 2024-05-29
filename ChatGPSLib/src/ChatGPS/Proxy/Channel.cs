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
    private Channel(int idleTimeoutMs = 0, string? proxyHostPath = null, string? logFilePath = null)
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
        this.idleTimeoutMs = idleTimeoutMs == 0 ? 60000 : idleTimeoutMs;
    }

    static internal Channel GetActiveChannel(int idleTimeoutMs = 0, string? proxyHostPath = null, string? logFilePath = null, bool forceNewChannel = false)
    {
        if ( forceNewChannel || Channel.activeChannel is null )
        {
            Channel.activeChannel = new Channel(idleTimeoutMs, proxyHostPath, logFilePath);
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

        try
        {
            await this.process.WriteLineAsync(message);
        }
        catch (Exception)
        {
            Console.WriteLine("Write fault");
            throw;
        }

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

        string? result = null;

        try
        {
            result = await this.process.ReadLineAsync();
        }
        catch (Exception)
        {
            Console.WriteLine("Read fault");
            throw;
        }

        return result;
    }

    public void Reset()
    {
        if ( ( this.process is not null ) && ! this.process.HasExited )
        {
            this.process.Stop();
        }

        this.process = null;
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

            var logFilePathArgument = this.logFilePath is not null ? $"--logfile {this.logFilePath}" : "";

            this.process = new Process(this.proxyHostPath, $"--timeout {this.idleTimeoutMs} {logFilePathArgument}".Trim());
        }

        this.process.Start();
    }

    static string? defaultProxyPath;
    static string? defaultLogFilePath;
    static Channel? activeChannel;

    Process? process;
    string proxyHostPath;
    string? logFilePath;
    int idleTimeoutMs;
}
