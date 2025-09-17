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
Stops the shell agent and removes its state.

.DESCRIPTION
Stop-ChatAgent stops the shell agent started by Start-ChatAgent. It also removes any state associated with the agent such as transcripts of PowerShell session output that may contain private data.

.PARAMETER SessionName
The name property of an existing session on which to enable to agent.

.OUTPUTS
None.

.EXAMPLE

.LINK
Start-ChatAgent
Add-ChatPlugin
Set-ChatAgentAccess
#>
function Stop-ChatAgent {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session
    )

    begin {}

    process {
        $targetSession = if ( $Session ) {
            $Session
        } else {
            Get-ChatSession -Current
        }

        if ( ! ( GetShellAgentStatus $targetSession  ) ) {
            return
        }

        $transcriptPath = GetAgentTranscriptPath $targetSession

        if ( $transcriptPath ) {
            Stop-Transcript -ErrorAction Ignore | out-null
            $transcriptPath | remove-item
        }

        UpdateClientContext $targetSession -ForgetTranscript

        SetShellAgentStatus $targetSession $false
    }

    end {}
}
