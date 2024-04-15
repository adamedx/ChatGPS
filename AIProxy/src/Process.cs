//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.AIProxy;

using System.Diagnostics;

internal class Process
{
    internal Process(TimeSpan? lifetime, bool hidden = true)
    {
        this.hidden = hidden;
        this.process = new System.Diagnostics.Process();
    }

    void Start(string? commandLine = null)
    {
    }

    void Stop(int? exitCode = null)
    {
    }

    void WriteConsole(string? content, bool noNewLine = false)
    {
    }

    void WriteError(string? content, bool noNewLine = false)
    {
    }

    private System.Diagnostics.Process process;
    private bool hidden = true;
}
