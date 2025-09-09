//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using Microsoft.SemanticKernel;
using System.ComponentModel;

namespace Modulus.ChatGPS.Plugins;

[System.ComponentModel.Description("Users of this plugin are using PowerShell as the user experience to access this application, and this plugin is likely executing outside of that PowerShell process. This plugin enables the ability to read information about the operating system environment of the PowerShell instance currently being accessed by the user to invoke this plugin.")]
public sealed class LocalContextNativePlugin
{
    public LocalContextNativePlugin() {}

    public LocalContextNativePlugin(IShellContext context)
    {
        this.context = context;
    }

    [System.ComponentModel.Description("Gets the process id of the user's application process.")]
    [KernelFunction]
    public int? get_process_id()
    {
        return this.context?.ProcessId;
    }

    [System.ComponentModel.Description("Gets the friendly name of the user's application process.")]
    [KernelFunction]
    public string? get_process_name()
    {
        return this.context?.ProcessName;
    }

    [System.ComponentModel.Description("Gets the version number of the PowerShell instance that the user is using in accessing this application.")]
    [KernelFunction]
    public string? get_process_powershell_version()
    {
        return this.context?.PSVersion;
    }

    [System.ComponentModel.Description("Gets the version number and name of the operating system hosting the PowerShell instance that the user is using to accessing this application.")]
    [KernelFunction]
    public string? get_operating_system()
    {
        return this.context?.OperatingSystem;
    }

    [Description("Returns the current working directory of the process that the user is using to access this application")]
    [KernelFunction]
    public string? get_current_directory()
    {
        return context?.CurrentDirectory;
    }

    IShellContext? context = null;
}
