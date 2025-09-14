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
Clears potentially orphaned system state managed by the shell agent removing sensitive data and freeing system resources.

.DESCRIPTION
Clear-ChatAgent removes state created by Start-ChatAgent. Start-ChatAgent can create text logs of PowerShell session text output; it is normally removed by the use of Stop-ChatAgent, but if PowerShell is executed without executing Stop-ChatAgent, any such files will be orphaned. These files may contain sensitive information since they can include any output the was entered into a terminal as well as the output returned by commands. To ensure unneeded files are removed and no longer a risk to expose private information, use the Clear-ChatAgent command.

Note: You can use the Get-ChatSession command to see the location of such state including the transcript path by sending its output to Format-List.

.OUTPUTS
None.

.EXAMPLE

.LINK
Start-ChatAgent
Stop-ChatAgent
#>
function Clear-ChatAgentState {
    [cmdletbinding(positionalbinding=$false)]
    param()

    $transcriptRoot = GetTranscriptDirectory

    $transcriptPattern = GetTranscriptPathFromIds $transcriptRoot -MatchAll

    Get-ChildItem $transcriptPattern | remove-item
}
