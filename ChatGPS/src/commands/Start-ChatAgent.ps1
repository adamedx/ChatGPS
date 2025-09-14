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
            '~/.chatgps/session/AgentTranscripts'
        }

        $targetDirectory = if ( ( test-path $transcriptDirectoryPath ) ) {
            Get-Item $transcriptDirectoryPath
        } else {
            new-item -type directory -force $transcriptDirectoryPath
        }

        $transcriptPath = join-path $targetDirectory "AgentTranscript-$($targetSession.Id)).txt"

        Start-Transcript -Path $transcriptPath | out-null

        UpdateClientContext $targetSession $transcriptPath
    }

    SetShellAgentStatus $targetSession $true
}

