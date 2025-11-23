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

using Microsoft.Agents.AI;
using System.ComponentModel;
using Modulus.ChatGPS.Compatibility;
using Modulus.ChatGPS.Utilities;

namespace Modulus.ChatGPS.Plugins;

[Description("Users of this plugin are using PowerShell as the user experience to access this application, and this plugin is likely executing outside of that PowerShell process. This plugin enables the ability to to obtain information about the operating system environment of the PowerShell instance currently being accessed by the user to invoke this plugin and to read the user's terminal output.")]
public sealed class LocalContextNativePlugin
{
    public LocalContextNativePlugin() {}

    public LocalContextNativePlugin(IShellContext context)
    {
        this.context = context;
    }

    [KernelFunction, Description("Gets the process id of the user's application process.")]
    public int? get_process_id()
    {
        return this.context?.ProcessId;
    }

    [KernelFunction, Description("Gets the friendly name of the user's application process.")]
    public string? get_process_name()
    {
        return this.context?.ProcessName;
    }

    [KernelFunction, Description("Gets the version number of the PowerShell instance that the user is using in accessing this application.")]
    public string? get_process_powershell_version()
    {
        return this.context?.PSVersion;
    }

    [KernelFunction, Description("Gets the version number and name of the operating system hosting the PowerShell instance that the user is using to accessing this application.")]
    public string? get_operating_system()
    {
        return this.context?.OperatingSystem;
    }

    [KernelFunction, Description("Returns the current working directory of the process that the user is using to access this application")]
    public string? get_current_directory()
    {
        return context?.CurrentDirectory;
    }

    [KernelFunction, Description("Returns the path to the PowerShell command history file")]
    public string? get_command_history_file_path()
    {
        return context?.HistoryFilePath;
    }

    [KernelFunction, Description("Returns a path that contains the terminal output of the user's PowerShell session, including all user input and command output, both success output and error output as text.")]
    public string? get_command_transcript_file_path()
    {
        return context?.TranscriptPath;
    }


    [KernelFunction, Description("Returns the most recent N lines of commands executed with PowerShell")]
    public string? get_most_recent_commands_from_history(int count_of_commands)
    {
        string? result = null;

        if ( context?.HistoryFilePath is not null )
        {
            var historyReader = new TailReader(count_of_commands);

            result = historyReader.ReadTail(context.HistoryFilePath);
        }

        return result;
    }

    [KernelFunction, Description("Returns the most recent N lines of the user's PowerShell session terminal output as it was rendered, including both the user's input command text and the resulting output of those commands, both success and error output. It is best to read at least a screenful of lines, for example 50 lines or so at least (50 is a good default), but it is also good to read more if you want to look further into previous command output to help the user.")]
    public string? get_latest_terminal_output(int count_of_lines)
    {
        string? result = null;

        if ( context?.TranscriptPath is not null )
        {
            var transcriptReader = new TailReader(count_of_lines);

            result = transcriptReader.ReadTail(context.TranscriptPath);
        }
        else
        {
            result = "";
        }

        return result;
    }

    IShellContext? context = null;
}
