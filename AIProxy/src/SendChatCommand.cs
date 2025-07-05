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

using System.Text.Json;
using System.Collections.Generic;
using Microsoft.SemanticKernel.ChatCompletion;

using Modulus.ChatGPS.Models.Proxy;
using Modulus.ChatGPS.Plugins;

internal class SendChatCommand : Command
{
    internal SendChatCommand(CommandProcessor processor, Guid serviceConnectionId) : base(processor)
    {
        this.serviceConnectionId = serviceConnectionId;
    }

    internal override ProxyResponse.Operation[] Process(CommandRequest? arguments, bool whatIf = false)
    {
        if ( arguments is null )
        {
            throw new ArgumentException("sendchat command missing required arguments");
        }

        var operation = new ProxyResponse.Operation("sendchat", Invoke);

        this.arguments = (SendChatRequest) arguments;

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        if ( this.arguments is null || this.arguments.History is null )
        {
            throw new ArgumentException("Invalid arguments specified for chat command");
        }

        var connection = this.processor.Connections.GetConnection(this.serviceConnectionId);

        PluginTable.SynchronizePlugins(connection.ChatService.Plugins, this.arguments.Plugins);

        var task = connection.ChatService.GetChatCompletionAsync(this.arguments.History, this.arguments.AllowFunctionCall);

        var result = task.Result;

        var response = new SendChatResponse( ( result is not null ) ? result[result.Count - 1].Content : null );

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<SendChatResponse>(response, jsonOptions);
    }

    private SendChatRequest? arguments;
    private Guid serviceConnectionId;
}

