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

set-strictmode -version 2
$erroractionpreference = 'stop'

function Trace-ProxyLog {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [string] $LogFile = '~/AIProxyLog.log',

        [parameter(position=1)]
        [ScriptBlock] $ProcessBlock,

        [parameter(parametersetname='interactive')]
        [switch] $All,

        [parameter(parametersetname='interactive')]
        [int32] $Last = 10,

        [switch] $Wait,

        [switch] $Raw,

        [parameter(parametersetname='asjob', mandatory=$true)]
        [switch] $AsJob
    )

    $targetFilePath = (Get-Item $LogFile).FullName

    $targetScript = if ( $ProcessBlock ) {
        $ProcessBlock
    } elseif ( ! $Raw.IsPresent ) {
        {param($logRecord) $logRecord | ConvertFrom-Json | Select Timestamp, Body}
    } else {
        {param($logRecord) $logRecord }
    }

    $countParam = if ( $All.IsPresent ) {
        @{}
    } elseif ( ! $Wait.IsPresent -and $Last -gt 0 ) {
        @{Tail=$Last}
    }

    if ( $null -ne $countParam ) {
        Get-Content $targetFilePath -Encoding Utf8 @countParam | foreach {
            & $targetScript $_
        }
    }

    if ( $Wait.IsPresent ) {
        $monitorBlock = {
            param($logFilePath, $processScript)
            Get-Content $logFilePath -Encoding Utf8 -Wait |
              foreach {
                  & $processScript $_
              }
        }

        if ( ! $AsJob.IsPresent ) {
            & $monitorBlock $targetFilePath $targetScript
        } else {
            $modulePath = $myinvocation.mycommand.Module.Path
            $initScript = [ScriptBlock]::Create("import-module '$modulePath'")
            Start-Job -InitializationScript $initScript -ScriptBlock {
                param($monitorScript, $logFilePath, $processScript)
                $monitorScriptBlock = [ScriptBlock]::Create($monitorScript)
                $processScriptBlock = [ScriptBlock]::Create($processScript)
                & $monitorScriptBlock $logFilePath $processScriptBlock
            } -ArgumentList $monitorBlock, $targetFilePath, $targetScript
        }
    }
}
