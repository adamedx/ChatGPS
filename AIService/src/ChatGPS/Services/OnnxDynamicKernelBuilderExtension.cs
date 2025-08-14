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

using Microsoft.SemanticKernel;

using Modulus.ChatGPS.Models;

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

    internal void AddOnnxService( IKernelBuilder onnxKernelBuilder, string modelIdentifier, string localModelPath )
    {
        if ( OnnxDynamicKernelBuilderExtension.onnxBuilderMethod is null )
        {
            var callingAssemblyPath = Assembly.GetCallingAssembly().Location;
            var callingAssemblyDirectory = Path.GetDirectoryName(callingAssemblyPath);

            var onnxAssemblyPath = Path.Join(callingAssemblyDirectory, onnxAssemblyFileName);

            Assembly? onnxAssembly;

            try
            {
                onnxAssembly = System.Reflection.Assembly.LoadFrom(onnxAssemblyPath);
            }
            catch ( Exception e )
            {
                throw new TypeLoadException($"Unable to initialize local Onnxmodel support. Could not load type {onnxBuilderTypeName} from the assembly path {onnxAssemblyPath}.", e);
            }

            var onnxBuilderType = onnxAssembly.GetType(onnxBuilderTypeName);

            if ( onnxBuilderType is null )
            {
                throw new TypeLoadException($"Unable to initialize local Onnxmodel support. Could not load type {onnxBuilderTypeName} from the successfully loaded assembly at the path {onnxAssemblyPath}.");
            }

            OnnxDynamicKernelBuilderExtension.onnxBuilderMethod = onnxBuilderType.GetMethod(
                onnxBuilderMethodName,
                BindingFlags.Public | BindingFlags.Static);

            if ( OnnxDynamicKernelBuilderExtension.onnxBuilderMethod is null )
            {
                throw new MissingMethodException($"The static method {onnxBuilderMethodName} was not found on type {onnxBuilderTypeName}.");
            }
        }

        OnnxDynamicKernelBuilderExtension.onnxBuilderMethod.Invoke(null, new object?[] { onnxKernelBuilder, modelIdentifier, localModelPath, null, null });
    }

    const string onnxAssemblyFileName = "Microsoft.SemanticKernel.Connectors.Onnx.dll";
    const string onnxBuilderTypeName = "Microsoft.SemanticKernel.OnnxKernelBuilderExtensions";
    const string onnxBuilderMethodName = "AddOnnxRuntimeGenAIChatCompletion";

    static MethodInfo? onnxBuilderMethod = null;
}

