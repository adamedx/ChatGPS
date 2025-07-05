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
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Models.Proxy;

public class SendChatRequest : CommandRequest
{
    public SendChatRequest() {}

    // This constructor is used by clients without access to SK types
    public SendChatRequest(ChatMessageHistory chatHistory, IEnumerable<Plugin>? plugins, bool? allowFunctionCall)
    {
        this.History = chatHistory.SourceHistory;
        this.AllowFunctionCall = allowFunctionCall;
        this.Plugins = plugins;
    }

    public SendChatRequest(ChatHistory chatHistory, IEnumerable<Plugin>? plugins, bool? allowFunctionCall)
    {
        this.History = chatHistory;
        this.AllowFunctionCall = allowFunctionCall;
        this.Plugins = plugins;
    }

    public ChatHistory? History { get; set; }
    public bool? AllowFunctionCall { get; set; }
    public IEnumerable<Plugin>? Plugins { get; set; }
}

