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

using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace Modulus.ChatGPS.Plugins;

public class ShellContext : IShellContext
{
    public ShellContext()
    {
        this.ProcessId = 0;
    }

    public ShellContext(IShellContext context)
    {
        this.ProcessId = context.ProcessId;
        this.ProcessName = context.ProcessName;
        this.PSVersion = context.PSVersion;
        this.UICulture = context.UICulture;
        this.OperatingSystem = context.OperatingSystem;
        this.HistoryFilePath = context.HistoryFilePath;
        this.CurrentDirectory = context.CurrentDirectory;
        this.TranscriptPath = context.TranscriptPath;
    }

    public void Initialize(string? psVersion = null, string? historyFilePath = null, string? transcriptPath = null)
    {
        if ( this.ProcessId != 0 )
        {
            throw new InvalidOperationException("The object may not be re-initialized.");
        }

        var process = Process.GetCurrentProcess();

        this.ProcessId = process.Id;
        this.ProcessName = process.ProcessName;
        this.PSVersion = psVersion;
        this.UICulture = Thread.CurrentThread.CurrentUICulture.ToString();
        this.OperatingSystem = System.Environment.OSVersion.VersionString;
        this.HistoryFilePath = historyFilePath;
        this.CurrentDirectory = System.Environment.CurrentDirectory;
        this.TranscriptPath = transcriptPath;
    }

    public void Update(string currentDirectory)
    {
        this.CurrentDirectory = currentDirectory;
    }

    public void Update(IShellContext? shellContext)
    {
        if ( shellContext is not null )
        {
            this.CurrentDirectory = shellContext.CurrentDirectory;
            this.TranscriptPath = shellContext.TranscriptPath;
        }
    }

    public int? ProcessId { get; set; }

    public string? ProcessName { get; set; }

    public string? PSVersion { get; set; }

    public string? UICulture { get; set; }

    public string? HistoryFilePath { get; set; }

    public string? CurrentDirectory { get; set; }

    public string? TranscriptPath { get; set; }

    public string? OperatingSystem { get; set; }
}
