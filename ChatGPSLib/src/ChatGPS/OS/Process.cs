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

