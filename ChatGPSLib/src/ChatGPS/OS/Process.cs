//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.OS;

using System.Diagnostics;

internal class Process
{
    internal Process(string imageFilePath, string? arguments = null, bool hidden = true)
    {
        this.imageFilePath = imageFilePath;
        this.arguments = arguments;
        this.hidden = hidden;
        this.processStarted = false;
        this.process = new System.Diagnostics.Process();
    }

    internal void Start(string? commandLine = null)
    {
        if ( ! this.processStarted )
        {
            this.process.StartInfo.FileName = imageFilePath;
            this.process.StartInfo.Arguments = arguments;
            this.process.StartInfo.RedirectStandardError = true;
            this.process.StartInfo.RedirectStandardOutput = true;
            this.process.StartInfo.RedirectStandardInput = true;
            this.process.StartInfo.UseShellExecute = false;

            this.process.Start();

            this.processStarted = true;
        }
        else if ( this.process.HasExited )
        {
            throw new InvalidOperationException("The process may not be restarted after it has exited.");
        }
    }

    internal void Stop()
    {
        this.process.Close();
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

    internal bool HasExited
    {
        get
        {
            return ! this.processStarted || this.process.HasExited;
        }
    }

    internal bool IsActive
    {
        get
        {
            return this.processStarted && ! this.process.HasExited;
        }
    }

    private System.Diagnostics.Process process;
    private string imageFilePath;
    private string? arguments;
    private bool hidden = true;
    private bool processStarted = false;
}
