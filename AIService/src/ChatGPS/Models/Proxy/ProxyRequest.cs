//
// Copyright (c), Adam Edwards
//
// All rights reserved.
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
            new Guid(),
            targetConnectionId);
    }

    public Guid RequestId { get; set; }
    public string? CommandName { get; set; }
    public string? Content { get; set; }
    public Guid TargetConnectionId { get; set; }
}
