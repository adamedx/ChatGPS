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
    public Channel(int idleTimeOutMs = 0, string? proxyHostPath = null)
    {
        string? targetImagePath =
            proxyHostPath is not null ?
            proxyHostPath :
            Channel.defaultProxyPath;

        if ( targetImagePath is null )
        {
            throw new ArgumentException("The path for the proxy must not be null");
        }

        this.proxyHostPath = targetImagePath;
        this.idleTimeoutMs = idleTimeoutMs == 0 ? 60000 : idleTimeoutMs;
    }

    public Task SendMessageAsync(string message)
    {
        InitializeChannel();

        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        return this.process.WriteLineAsync(message);
    }

    public void SetProxyHostPath(string proxyHostPathValue)
    {
        if ( this.proxyHostPath != null )
        {
            throw new InvalidOperationException("The proxy host path is already set and may not be set again.");
        }

        this.proxyHostPath = proxyHostPathValue;
    }

    public async Task<string> ReadMessageAsync()
    {
        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        var response = await this.process.ReadLineAsync();

        return response != null ? response : "";
    }

    public void Reset()
    {
        if ( ( this.process is not null ) && ! this.process.HasExited )
        {
            this.process.Stop();
        }

        this.process = null;
    }

    internal static void SetDefaultProxyPath(string defaultProxyPath)
    {
        Channel.defaultProxyPath = defaultProxyPath;
    }

    void InitializeChannel()
    {
        if ( this.process is null || this.process.HasExited )
        {
            if ( this.proxyHostPath is null )
            {
                throw new InvalidOperationException("The proxy host path has not been set; it must be set before a channel can be initialized");
            }

            this.process = new Process(this.proxyHostPath, $"--timeout {this.idleTimeoutMs} --logfile c:\\users\\adame\\proxylog.txt");
        }

        this.process.Start();
    }

    static string? defaultProxyPath;

    Process? process;
    string proxyHostPath;
    int idleTimeoutMs;
}
