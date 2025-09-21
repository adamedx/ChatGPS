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

.PARAMETER SessionName
The name property of an existing session on which to enable to agent.

.OUTPUTS
None.

.EXAMPLE

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

