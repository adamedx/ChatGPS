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

[cmdletbinding(PositionalBinding=$false)]
param(
    [parameter(mandatory=$true)]
    [string] $ModuleName,

    [parameter(mandatory=$true)]
    [string] $CommandHelpRelativeDirectory
)

set-strictmode -version 2
$ErrorActionPreference = 'stop'

$module = Get-Module $ModuleName -ErrorAction Stop

if ( ! $Module ) {
    throw [ArgumentException]::new("Unable to load the module '$Module'")
}

$commandInfo = $module |
  select-object -ExpandProperty ExportedFunctions |
  select-object -ExpandProperty values |
  select-object -ExpandProperty name |
  foreach {
      get-help $_ | select-object name, synopsis
  }


$commandTable = foreach ( $command in $commandInfo ) {
    "|[$($command.Name)]($($CommandHelpRelativeDirectory)/$($command.Name))|$($command.Synopsis)|`n"
}



$documentPrologue = @'
Command Reference
=================

|[Documentation Home](Introduction.md)|
|-------------------------------------|

|Command|Description|
|-------|-----------|
'@

$documentPrologue + "`n" + $commandTable

