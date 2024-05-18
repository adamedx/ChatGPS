//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.OS;

using System.Diagnostics;

internal class Process
{
    internal Process(TimeSpan? lifetime, bool hidden = true)
    {
        this.hidden = hidden;
        this.process = new System.Diagnostics.Process();
    }

    internal void Start(string? commandLine = null)
    {
    }

    internal void Stop(int? exitCode = null)
    {
    }

    internal async Task WriteLineAsync(string? content, bool noNewLine = false)
    {
        var targetContent = noNewLine ? content : $"{content}\n";

        await this.process.StandardInput.WriteAsync(targetContent);

        return;
    }

    internal async Task<string?> ReadLineAsync()
    {
        return await this.process.StandardOutput.ReadLineAsync();
    }

    private System.Diagnostics.Process process;
    private bool hidden = true;
//    private bool stopping = false;
}
