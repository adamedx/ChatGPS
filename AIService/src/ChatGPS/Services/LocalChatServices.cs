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

using System.Collections.Generic;
using System.Reflection;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class LocalChatService : ChatService
{
    internal LocalChatService(AiOptions options, ILoggerFactory? loggerFactory = null) : base(options, loggerFactory) { }

    protected override Kernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier == null )
        {
            throw new ArgumentException("An identifier for the language model must be specified.");
        }

        var builder = base.GetKernelBuilder();

        if ( this.options.LocalModelPath == null )
        {
            throw new ArgumentException("A file system path must be specified.");
        }

#if DEBUG
#pragma warning disable SKEXP0070
        builder.AddOnnxRuntimeGenAIChatCompletion(this.options.ModelIdentifier, this.options.LocalModelPath);
#pragma warning restore SKEXP0070

        var assemblyLoader = new OnnxProviderAssemblyLoader();

        if ( ! assemblyLoader.IsSupportedOnCurrentPlatform )
        {
            var osVersion = System.Environment.OSVersion.ToString();
            var processArch = System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture;

            throw new PlatformNotSupportedException($"This application does not support the use of Onnx local models " +
                                                    "on the current system platform '{osVersion}, {processArch}'. " +
                                                    "Onnx support currently requires the Windows operating system executing " +
                                                    "on the x64 or arm64 processor architectures.");
        }
#else
        if ( LocalChatService.onnxBuilderMethod is null )
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
                throw new TypeLoadException($"Unable to initialize local Onnxmodel support. Could not load type 'Microsoft.SemanticKernel.OnnxKernelBuilderExtensions' from the assembly path {onnxAssemblyPath}.", e);
            }

            var onnxBuilderType = onnxAssembly.GetType(onnxBuilderTypeName);

            if ( onnxBuilderType is null )
            {
                throw new TypeLoadException("Unable to initialize local Onnxmodel support. Could not load type 'Microsoft.SemanticKernel.OnnxKernelBuilderExtensions' from the successfully loaded assembly Microsoft.SemanticKernel.Connectors.Onnx.");
            }

            LocalChatService.onnxBuilderMethod = onnxBuilderType.GetMethod(
                onnxBuilderMethodName,
                BindingFlags.Public | BindingFlags.Static);

            if ( LocalChatService.onnxBuilderMethod is null )
            {
                throw new MissingMethodException("The static method AddOnnxRuntimeGenAIChatCompletion was not found on OnnxKernelBuilderExtensions.");
            }
        }

        LocalChatService.onnxBuilderMethod.Invoke(null, new object?[] { builder, this.options.ModelIdentifier, this.options.LocalModelPath, null, null });
#endif
        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
    }

#if !DEBUG
    const string onnxAssemblyFileName = "Microsoft.SemanticKernel.Connectors.Onnx.dll";
    const string onnxBuilderTypeName = "Microsoft.SemanticKernel.OnnxKernelBuilderExtensions";
    const string onnxBuilderMethodName = "AddOnnxRuntimeGenAIChatCompletion";

    static MethodInfo? onnxBuilderMethod = null;
#endif
}

