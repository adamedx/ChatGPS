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
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

using Modulus.ChatGPS.Models.Proxy;

internal class InvokeFunctionCommand : Command
{
    internal InvokeFunctionCommand(CommandProcessor processor, Guid serviceConnectionId) : base(processor)
    {
        this.serviceConnectionId = serviceConnectionId;
    }

    internal override ProxyResponse.Operation[] Process(CommandRequest? arguments, bool whatIf = false)
    {
        if ( arguments is null )
        {
            throw new ArgumentException("invokefunction command missing required arguments");
        }

        var operation = new ProxyResponse.Operation("invokefunction", Invoke);

        this.arguments = (InvokeFunctionRequest) arguments;

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        if ( this.arguments is null || this.arguments.DefinitionPrompt is null || this.arguments.Parameters is null )
        {
            throw new ArgumentException("Invalid arguments specified for invokefunction command");
        }

        var connection = this.processor.Connections.GetConnection(this.serviceConnectionId);

        PluginTable.SynchronizePlugins(connection.ChatService.Plugins, this.arguments.Plugins);

        var task = connection.ChatService.InvokeFunctionAsync(this.arguments.DefinitionPrompt, this.arguments.Parameters, this.arguments.AllowFunctionCall);

        var result = task.Result;

        var response = new InvokeFunctionResponse( result );

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<InvokeFunctionResponse>(response, jsonOptions);
    }

    InvokeFunctionRequest? arguments;
    private Guid serviceConnectionId;
}


