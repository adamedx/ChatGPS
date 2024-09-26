//
// Copyright 2024, Adam Edwards
//
// All rights reserved.
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
