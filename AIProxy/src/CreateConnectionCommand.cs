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

using Modulus.ChatGPS.Models.Proxy;

internal class CreateConnectionCommand : Command
{
    internal CreateConnectionCommand(CommandProcessor processor) : base(processor) {}

    internal override ProxyResponse.Operation[] Process(CommandRequest? request, bool whatIf = false)
    {
        if ( request is null )
        {
            throw new ArgumentException("createconnection command missing required arguments");
        }

        this.connectionArguments = (CreateConnectionRequest) request;

        var operation = new ProxyResponse.Operation("createconnection", Invoke);

        if ( ! whatIf )
        {
            operation.Invoke();
        }

        return new ProxyResponse.Operation[] { operation };
    }

    private string? Invoke(ProxyResponse.Operation operation)
    {
        if ( this.connectionArguments is null )
        {
            throw new ArgumentException("No connection arguments were specified");
        }

        var newConnection = this.processor.Connections.NewConnection(this.connectionArguments.ConnectionOptions);
        var response = new CreateConnectionResponse(newConnection.Id, newConnection.ChatService.ServiceOptions);

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<CreateConnectionResponse>(response, jsonOptions);
    }

    private CreateConnectionRequest? connectionArguments;
}

