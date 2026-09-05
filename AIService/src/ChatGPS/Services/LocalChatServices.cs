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

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;


public class LocalChatService : ChatService
{
    internal LocalChatService(AiOptions options, ILoggerFactory? loggerFactory = null) : base(options, loggerFactory) { }

    protected override IAIKernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier == null )
        {
            throw new ArgumentException("An identifier for the language model must be specified.");
        }

        if ( this.options.LocalModelPath == null )
        {
            throw new ArgumentException("A file system path must be specified.");
        }

        var onnxBuilderExtension = new OnnxDynamicKernelBuilderExtension();

        if ( ! onnxBuilderExtension.IsSupportedOnCurrentPlatform )
        {
            throw new PlatformNotSupportedException($"This application does not support the use of Onnx local models " +
                                                    "on the current system platform '{onnxBuilderExtension.PlatformString}'. " +
                                                    "Onnx support currently requires the Windows operating system executing " +
                                                    "on the x64 or arm64 processor architectures.");
        }

        var chatClient = onnxBuilderExtension.CreateChatClient(
            this.options.ModelIdentifier,
            this.options.LocalModelPath,
            this.options.LocalModelProvider,
            this.options.LocalModelProviderOptions);
        var newKernel = new AIKernel(chatClient);

        this.serviceKernel = newKernel;

        return newKernel;
    }
}
