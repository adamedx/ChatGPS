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

using System.Reflection;
using System.Runtime.InteropServices;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class OnnxProviderAssemblyLoader
{
    public OnnxProviderAssemblyLoader()
    {
        InitializePlatformInfo();
    }

    public bool IsSupportedOnCurrentPlatform
    {
        get
        {
            return this.isOsSupported && this.isArchSupported;
        }
    }

    private void InitializePlatformInfo()
    {
        // Note that an unsupported platform is not a fatal error in general -- it just
        // means the specific features for Onnx support are unavailable. Higher level
        // error messages will indicate to users which platforms are supported.

        var osFragment = OperatingSystem.IsLinux() ?
            "linux" : (
                OperatingSystem.IsMacOS() ?
                "osx" : (
                    OperatingSystem.IsWindows() ?
                    "win" : null ) );

        this.isOsSupported = osFragment != null;

        string? archFragment = null;

        if ( this.isOsSupported )
        {
            switch ( RuntimeInformation.ProcessArchitecture )
            {
            case Architecture.X64:
                archFragment = "x64";
                break;

            case Architecture.Arm64:
                archFragment = "arm64";
                break;
            }
        }

        if ( archFragment != null )
        {
            this.isArchSupported = true;

            var callingAssemblyPath = Assembly.GetCallingAssembly().Location;
            this.callingAssemblyDirectory = Path.GetDirectoryName(callingAssemblyPath);

            var currentNativePlatformIdentifier = $"{osFragment}-{archFragment}";
            var targetPlatformSubdirectory = Path.Join("runtimes", currentNativePlatformIdentifier);
            var targetSubdirectory = Path.Join(targetPlatformSubdirectory, "native");

            this.targetAssemblyDirectory = Path.Join(this.callingAssemblyDirectory, targetSubdirectory);
        }
    }

    private bool isOsSupported = false;
    private bool isArchSupported = false;
    private string? callingAssemblyDirectory;
    private string? targetAssemblyDirectory;
}

