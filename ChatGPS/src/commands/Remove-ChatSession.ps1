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


<#
.SYNOPSIS
Removes a chat session from the list of defined chat sessions, rendering it inaccessible and thus unusable.

.DESCRIPTION
Remove-ChatSession removes a chat session from the list of defined chatsessions. A chat session is required for ChatGPS commands to interact with language models. For more information on chat sessions, see the documentation for the Connect-ChatSession command.

By issuing this command for a defined chat session, the chat session becomes inaccessible to other ChatGPS commands such as Send-ChatMessage, Invoke-ChatFunction, Start-ChatShell, etc., and thus it can no longer be used.

Removing a chat session can be useful if the list of defined chat sessions returned by Get-ChatSession is unwieldy, or if the given chat session settings are no longer valid (e.g. the model it uses is no longer supported by its provider) and the session is no longer usable.

Note that the command will fail by default if an attempt is made to remove the current session, but this can be overridden by specifying the Force parameter; if the current session is removed, another session will become the current session if there are other sessions.

.PARAMETER SessionName
The name of the session to be removed.

.PARAMETER Id
The identifier of the session to be removed.


.OUTPUTS
None.

.EXAMPLE
PS > Get-ChatSession
 
Info   Name         Model                Provider    Count
----   ----         -----                --------    -----
+rd-   az-4.1-mini  gpt-4.1-mini         AzureOpenAI 1
 rcs   GPT4omini    gpt-4o-mini          OpenAI      7
+rdx > azure-int    gpt-4o-mini          AzureOpenAI 28
 
PS > Remove-ChatSession GPT4omini
PS > Get-ChatSession
 
Info   Name         Model                Provider    Count
----   ----         -----                --------    -----
+rd-   az-4.1-mini  gpt-4.1-mini         AzureOpenAI 1
+rdx > azure-int    gpt-4o-mini          AzureOpenAI 28

In this example, Get-ChatSession is first invoked to list the three defined sessions, and Remove-ChatSession is executed with the GPT4omini session name specified for the SessionName parameter. A subsequent invocation of Get-ChatSession shows that list of defined sessions is down to two instead of three, and as expected the GPT4omini session specified to Remove-ChatSession is no longer part of that list.

.EXAMPLE
PS > Get-ChatSession
 
Info   Name         Model                Provider    Count
----   ----         -----                --------    -----
+rd-   az-4.1-mini  gpt-4.1-mini         AzureOpenAI 1
 rcs   GPT4omini    gpt-4o-mini          OpenAI      7
+rdx > azure-int    gpt-4o-mini          AzureOpenAI 28
 
PS > Get-ChatSession | Remove-ChatSession -Force
PS > Get-ChatSession | Measure-Object | Select-Object Count
 
Count
-----
    0

In this example, we start with three sessions listed by Get-ChatSession. Then the output of Get-ChatSession is piped to Remove-ChatSession, and a re-invocation of Get-ChatSession piped to Measure-Object shows that all chat sessions have been removed. The Force parameter was required when invoking Remove-ChatSession because otherwise the command would have halted with an error when attempting to remove the current session which is included in the list of sessions emitted by Get-ChatSession.

.LINK
Connect-ChatSession
Get-ChatSession
Select-ChatSession
#>
function Remove-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', mandatory=$true, position=0)]
        [Alias('Name')]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [switch] $Force
    )

    begin {
    }

    process {
        $nameOrId = if ( $SessionName ) {
            @{Name=$SessionName}
        } else {
            @{Id=$Id}
        }

        $session = Get-ChatSession @nameOrId

        RemoveSession $session $Force.IsPresent
    }

    end {
    }
}

RegisterSessionCompleter Remove-ChatSession SessionName
