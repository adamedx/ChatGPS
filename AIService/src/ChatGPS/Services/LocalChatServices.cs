//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class LocalAIChatService : ChatService
{
    internal LocalAIChatService(AiOptions options) : base(options) { }

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

        var builder = Kernel.CreateBuilder();

        if ( this.options.LocalModelPath == null )
        {
            throw new ArgumentException("A file system path must be specified.");
        }

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
    }
}
