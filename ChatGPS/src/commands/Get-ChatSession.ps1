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



function Get-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', position=0)]
        [Alias('Name')]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [parameter(parametersetname='current', mandatory=$true)]
        [switch] $Current
    )

    if ( $Current.IsPresent ) {
        GetCurrentSession
    } else {
        $sessions = GetChatSessions | where {
            ( $null -eq $Id -and $null -eq $SessionName ) -or
            ( $_.Name -eq $SessionName ) -or
            ( $_.Id -eq $Id )
        }

        if ( ! $sessions ) {
            if ( $Id ) {
                write-error "The session with the specified id '$Id' could not be found."
            } elseif ( $SessionName ) {
                write-error "The session with the specified name '$SessionName' could not be found."
            }
        }

        $sessions | where { !! $_.name } | sort-object Name
        $sessions | where { ! $_.name }
    }
}

RegisterSessionCompleter Get-ChatSession SessionName
RegisterSessionCompleter Get-ChatSession Id
