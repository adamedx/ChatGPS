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
using System.Collections.Generic;

using Microsoft.Extensions.AI;

namespace Modulus.ChatGPS.Services;

internal class OnnxDynamicKernelBuilderExtension
{
    internal OnnxDynamicKernelBuilderExtension()
    {
        this.PlatformString = null;
        InitializePlatformInfo();
    }

    internal bool IsSupportedOnCurrentPlatform
    {
        get
        {
            return this.PlatformString is not null;
        }
    }

    internal string? PlatformString { get; private set; }

    internal IChatClient CreateChatClient(
        string modelIdentifier,
        string modelPath,
        string? localModelProvider,
        Dictionary<string, string>? localModelProviderOptions)
    {
        var assemblyPath = Path.Combine(
            Path.GetDirectoryName(typeof(OnnxDynamicKernelBuilderExtension).Assembly.Location) ?? string.Empty,
            "addons.dll");

        Assembly onnxAssembly;

        try
        {
            onnxAssembly = Assembly.LoadFrom(assemblyPath);
        }
        catch (Exception exception)
        {
            throw new TypeLoadException(
                $"Unable to initialize local Onnx model support. Install the LocalOnnx add-on with Install-ChatAddOn and retry. " +
                $"The add-on assembly could not be loaded from '{assemblyPath}'.",
                exception);
        }

        var factoryType = onnxAssembly.GetType("Modulus.ChatGPS.Addons.OnnxChatClientFactory");
        var factoryMethod = factoryType?.GetMethod(
            "Create",
            BindingFlags.Public | BindingFlags.Static);

        if (factoryMethod is null)
        {
            throw new MissingMethodException(
                "The LocalOnnx add-on does not contain the expected OnnxChatClientFactory.Create method.");
        }

        try
        {
            return (IChatClient)(factoryMethod.Invoke(
                    null,
                    new object?[]
                    {
                        modelIdentifier,
                        modelPath,
                        localModelProvider,
                        localModelProviderOptions
                    })
                ?? throw new TypeLoadException("The LocalOnnx add-on returned no chat client."));
        }
        catch (TargetInvocationException exception) when (exception.InnerException is not null)
        {
            throw exception.InnerException;
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

        var isOsSupported = osFragment != null;

        string? archFragment = null;

        if ( isOsSupported )
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
            this.PlatformString = $"{osFragment}-{archFragment}";
        }
    }

}
