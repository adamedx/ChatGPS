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

namespace Modulus.ChatGPS.Models.Proxy;

public class ProxyRequest : ProxyMessage
{
    public ProxyRequest() {}

    public ProxyRequest(ProxyRequest sourceRequest)
    {
        this.CommandName = sourceRequest.CommandName;
        this.RequestId = sourceRequest.RequestId;
        this.Content = sourceRequest.Content;
        this.TargetConnectionId = sourceRequest.TargetConnectionId;
    }

    public ProxyRequest(string commandName, string content, Guid requestId, Guid? targetConnectionId = null)
    {
        if ( requestId == Guid.Empty )
        {
            throw new ArgumentException("The RequestId field must be a valid non-empty Guid");
        }

        this.CommandName = commandName;
        this.RequestId = requestId;
        this.Content = content;
        this.TargetConnectionId = targetConnectionId != null ? (Guid) targetConnectionId : Guid.Empty;
    }

    public static ProxyRequest FromRequestCommand(CommandRequest commandRequest, Guid? targetConnectionId = null)
    {
        var serializedCommandRequest = JsonSerializer.Serialize(commandRequest, commandRequest.GetType(), ProxyMessage.jsonOptions);

        var commandName = CommandRequest.GetCommandNameFromRequestType(commandRequest.GetType());

        if ( commandName is null )
        {
            throw new ArgumentException("The type of the deserialized request command does not correspond to a known command");
        }

        return new ProxyRequest(
            commandName,
            serializedCommandRequest,
            Guid.NewGuid(),
            targetConnectionId);
    }

    public Guid RequestId { get; set; }
    public string? CommandName { get; set; }
    public string? Content { get; set; }
    public Guid TargetConnectionId { get; set; }
}

