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
Installs add-on components to the ChatGPS module for additional functionality.

.DESCRIPTION
ChatGPS provides access to many aspects of AI language model functionality. Because some capabilities including local Onnx model inferencing result in large PowerShell module sizes near 100MB, these capabilities are omitted from the ChatGPS PowerShell module published to PowerShell module repositories. Use the Install-ChatAddOn command to install the missing functionality to the ChatGPS module.

If the AddOn parameter is not specified to the command, then all AddOns are installed.

Currently the only supported add-on is LocalOnnx, which enables the use of local Onnx models. For more information about local model support, see the Connect-ChatSession command.

Because the functionality is not distributed through a PowerShell repository, the Install-ChatAddOn command will use other tools such as dotnet to obtain the required files from sources such as a nuget repository. If the tool required to download the capabilities is not available, the command attempts to install that tool as well.

Add-ons only need to be installed once to enable the functionality. If a failure is encountered during the execution of the command it is typically safe to re-invoke the command to retry. If the command is successful and the command is invoked again, the command will result in no operation unless the Force parameter is specified.

.PARAMETER AddOns
The add-ons to install. Currently the only supported add-on is LocalOnnx.

.PARAMETER UsePrivateDotNet
By default, when the dotnet tools is needed to install an add-on, the existing installed version of the dotnet tool is used if it is present, and a new version of the dotnet tool is not installed unless there is no current version or the current version is very old (pre-dating .Net 8). Specify this parameter to force installation and use of the dotnet tool even when an existing compatible version is found.

.PARAMETER PassThru
By default, the command returns no output. Specify PassThru to return the tools (e.g. PowerShell commands or other command-line tools such as dotnet) used to install the add-on. This can be useful for debugging installation failures and identifying workarounds.

.OUTPUTS
By default, no output is returned unless the PassThru parameter is specified.

.EXAMPLE
Install-ChatAddOn

This example installs all add-ons. Because no add-ons were specified with the AddOns parameter, all supported add-ons were installed.

.EXAMPLE
Install-ChatAddOn LocalOnnx -PassThru

C:\Program Files\dotnet\dotnet.exe

In this case an explicit add-on is specified via the AddOns parameter, and PassThrue is used to return the tool used to install the specified AddOn, which in this case was the dotnet tool.

.LINK
Connect-ChatSession
#>
function Install-ChatAddOn {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [ValidateSet('LocalOnnx')]
        [parameter(position=0)]
        [string[]] $AddOns = @('LocalOnnx'),

        [switch] $UsePrivateDotNet,

        [switch] $PassThru,

        [switch] $Force
    )

    $installTools = foreach ( $addOn in $AddOns ) {
        InstallLibs $UsePrivateDotNet.IsPresent $Force.IsPresent
    }

    if ( $PassThru.IsPresent ) {
        $installTools
    }
}
