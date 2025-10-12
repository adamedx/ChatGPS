#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


<#
.SYNOPSIS
Enables an agent that has awareness of the current PowerShell session.

.DESCRIPTION
Start-ChatAgent enables language model interaction with the PowerShell session used to invoke ChatGPS commands, i.e. the session in which the ChatGPS module is loaded. This can allow the AI to interact with your command history, actual terminal output, and get context about the current process id, the current directory , etc. This can allow the AI to assist in correcting errors in commands, explaining terminal output, or otherwise having the abilities of a person sitting next to you as you interact with powerShell.

Start-ChatAgent can create text logs of PowerShell session text output; it is normally removed by the use of Stop-ChatAgent, but if PowerShell is executed without executing Stop-ChatAgent, any such files will be orphaned. These files may contain sensitive information since they can include any output the was entered into a terminal as well as the output returned by commands. To ensure unneeded files are removed and no longer a risk to expose private information, use the Clear-ChatAgent command.

Note: You can use the Get-ChatSession command to see the location of such state including the transcript path by sending its output to Format-List.

.PARAMETER Session
The session on which to enable to agent. If this parameter is not specified, the agent is enabled for the current session.

.PARAMETER TranscriptDirectory
By default, the agent stores a PowerShell session transcript created by PowerShell's Start-Transcript comand in the directory ~/.chatgps/session/AgentTrascripts whenever the Start-ChatAgent command is invoked. To override the location specify TranscriptDirectory to utilize a custom location for the transcript. This is useful in cases where you may want to store these logs in a location outside of the user's profile for instance that has additional controls and security restrictions to protect data emitted by commands utilized in the PowerShell session.

.PARAMETER NoTranscript
Specifies that the agent should not create a transcript (created by Start-Transcript) of the PowerShell session terminal input and output. The agent will still track command history in this case, but output of commands will be invisible to the agent and no persistent records of the terminal output will be produced.

.OUTPUTS
None.

.EXAMPLE
Start-ChatAgent

This simple invocation starts the agent on the current session. Subsequent terminal input and output will be captured in a transcript and the agent will be able to consult the transcript to answer questions about any text visible to the terminal.

.EXAMPLE
Start-ChatAgent
 
PS > dotnet build | out-string
 
 Determining projects to restore...
  All projects are up-to-date for restore.
C:\Users\ryu\src\sockettest\Program.cs(11,23): warning CS8600: Converting null literal or possible null value to non-nullable type. [C:\Users\ryu\src\sockettest\sockettest.csproj]
  sockettest -> C:\Users\ryu\src\sockettest\bin\Debug\net8.0\sockettest.dll
 
Build succeeded.
 
C:\Users\ryu\src\sockettest\Program.cs(11,23): warning CS8600: Converting null literal or possible null value to non-nullable type. [C:\Users\ryu\src\sockettest\sockettest.csproj]
    1 Warning(s)
    0 Error(s)
 
Time Elapsed 00:00:01.51
 
PS > Send-ChatMessage "Can you look at my terminal output and propose a solution for the compiler warning that shows in the output?
 
Received                 Response
--------                 --------
10/11/2025 8:34:49 PM    The output indicates that you have a compiler warning:
                         ```
                         warning CS8600: Converting null literal or possible null value to non-nullable
                         type.
                         ```
                         This warning typically occurs in C# when you're trying to assign a value that
                         could potentially be `null` to a variable that is defined as non-nullable.
                         Specifically, this warning is located in the file `Program.cs` at line 11,
                         character 23.
 
                         ### Proposed Solutions:
...

In this example, the agent is started with Start-ChatAgent, and then the `dotnet build` command is piped to Out-String (more on that later) to compile a C# file, and this results in a warning. Then Send-ChatMessage is used to ask the agent for help regarding the error. The agent has access to the terminal output and can see the error without the user having to paste it and explicitly send it with Send-ChatMessage, and is able to return an answer (not all of which is shown here). Note that Out-String is used because the dotnet command in particular bypasses standard output and writes directly to the terminal, and this is not captured by the agent which is limited by the capbilities of the Powershell Start-Transcript command. By piping the output to Out-String, the command output is explicitly captured and then redirected to standard output where it is then visible to Start-Transcript and thus to the agent. Unlike some custom command-line tools like dotnet, native PowerShell commands emit to standard output and so this Out-String workaround is not needed; and most command-line tools that are not PowerShell-based also write to standard output (or have options to direct them to do so) rendering the workaround unnecessary in most cases.

.LINK
Stop-ChatAgent
Add-ChatPlugin
Set-ChatAgentAccess
#>
function Start-ChatAgent {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [string] $TranscriptDirectory,

        [switch] $NoTranscript
    )

    $targetSession = if ( $Session ) {
        $Session
    } else {
        Get-ChatSession -Current
    }

    if ( GetShellAgentStatus $targetSession ) {
        return
    }

    $contextPluginName = 'LocalContext'

    $hasContextPlugin = $null -ne (Get-ChatPlugin -Session $targetSession | where-object Name -eq $contextPluginName)

    if ( ! $hasContextPlugin ) {
        Add-ChatPlugin $contextPluginName
    }

    Set-ChatAgentAccess -Session $targetSession -Allowed

    if ( ! $NoTranscript.IsPresent ) {

        $transcriptDirectoryPath = if ( $TranscriptDirectory ) {
            $TranscriptDirectory
        } else {
            GetTranscriptDirectory
        }

        $targetDirectory = if ( ( test-path $transcriptDirectoryPath ) ) {
            Get-Item $transcriptDirectoryPath
        } else {
            new-item -type directory -force $transcriptDirectoryPath
        }

        $transcriptPath = GetTranscriptPathFromIds $targetDirectory $targetSession.Id

        $activeTranscriptCount = GetTranscriptCount

        if ( $activeTranscriptCount -eq 0 ) {
            Start-Transcript -Path $transcriptPath | out-null
        }

        UpdateClientContext $targetSession $transcriptPath
    }

    SetShellAgentStatus $targetSession $true
}

