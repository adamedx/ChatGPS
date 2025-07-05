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

$welcomeShown = $false

function ShowWelcome([bool] $hideWelcome) {
    if ( ! $hideWelcome -and ! $script:welcomeShown ) {
        $script:welcomeShown = $true
        $module = $myinvocation.mycommand.Module
        $moduleName = $module.Name
        $version = $module.Version
        $welcomeMessage = "`nWelcome to $moduleName Shell $version!`n"

        write-host -foreground green $welcomeMessage
        write-host -foreground cyan "$([DateTime]::now.ToString('F'))`n"
        write-host " * View configuration at $(GetDefaultSettingsLocation)"
        write-host " * Enter '.help' for a list of built-in shell commands"
    }
}
