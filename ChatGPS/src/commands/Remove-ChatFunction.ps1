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
Removes a chat function created by the New-ChatFunction command.

.DESCRIPTION
A chat function is created by the New-ChatFunction command. Chat functions can be specified to the Remove-ChatFunction command via the Id property of the function, or if the function has a name, its name can be used to identify the function to be deleted.

.PARAMETER Id
The Id of the property of the chat function to delete. All chat functions have an Id property, so this parameter can be used to remove any chat function, and is also supported from the pipeline.

.PARAMETER Name
The name of the chat function to delete. This can only be used of the function was created with a name.

.OUTPUTS
None.

.EXAMPLE
Remove-ChatFunction Summarizer

In this example, the chat function named Summarizer is deleted by specifying the Name property of the function to be deleted.

.EXAMPLE
Get-ChatFunction
Id                                   Name       Definition             Parameters
--                                   ----       ----------             ----------
59880abc-166f-48fd-a96d-220f793c4f57 Translator Translate the text {{$ {[language, language], [sourcetext, sourcetext]}
59880abc-166f-48fd-a96d-220f793c4f57 Summarizer Summarize the text {{$ {[sourcetext, sourcetext]}
PS > Get-ChatFunction | Remove-ChatFunction
PS > Get-ChatFunction | Measure-Object | Select-Object Count
 
Count
-----
    0
 
In this example, all existing chat functions are enumerated by the Get-ChatFunction command. After this, Remove-ChatFunction is invoked with the output of Get-ChatFunction as input to its pipeline -- this deletes all of the previously enmerated functions, leaving no chat functions. This can be seen by the last command executed, which now returns a count of 0 for chat functions returned by the Get-ChatFunction command; prior to the use of Remove-ChatFunction, it had returned two such functions.

.LINK
New-ChatFunction
Get-ChatFunction
Invoke-ChatFunction
New-ChatScriptBlock
#>
function Remove-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name
    )

    begin {
        $functions = GetFunctionInfo
    }

    process {
        $targetId = if ( $Name ) {
            $functions.GetFunctionByName($Name).Id
        } else {
            $Id
        }

        $functions.RemoveFunction($targetId)
    }

    end {
    }
}

[Function]::RegisterFunctionNameCompleter('Remove-ChatFunction', 'Name')
