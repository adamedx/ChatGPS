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
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class LocalAIChatService : ChatService
{
    internal LocalAIChatService(AiOptions options, ILoggerFactory? loggerFactory = null) : base(options, loggerFactory) { }

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

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
#else
        throw new NotImplementedException("Support for Onnx is temporarily disabled.");
#endif
    }


}

