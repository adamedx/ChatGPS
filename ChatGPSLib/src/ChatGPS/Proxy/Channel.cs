//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.IO;
using Modulus.ChatGPS.Communication;

namespace Modulus.ChatGPS.Proxy;

public class Channel : StdioChannel, IChannel
{
    public Channel(string proxyHostPath, int idleTimeoutMs = 60000, string? logFilePath = null, string? logLevel = null) :
        base(proxyHostPath)
    {
        this.idleTimeoutMs = idleTimeoutMs;
        this.logFilePath = logFilePath;
        this.logLevel = logLevel;
    }

    protected override string GetCommandArguments()
    {
        var logFilePathArgument = this.logFilePath is not null ? $"--logfile {this.logFilePath} " : "";
        var logLevelArgument = this.logLevel is not null ? $"--debuglevel {this.logLevel} " : "";

        return $"--timeout {this.idleTimeoutMs} {logLevelArgument}{logFilePathArgument}".Trim();
    }

    int idleTimeoutMs;
    string? logFilePath;
    string? logLevel;
}
