//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;

namespace Modulus.ChatGPS.Models.Proxy;

public class ProxyRequest
{
    public ProxyRequest() {}

    public ProxyRequest(string commandName, string content, Guid requestId)
    {
        this.CommandName = commandName;
        this.RequestId = requestId;
        this.Content = content;
    }

    public Guid RequestId { get; set; }
    public string? CommandName { get; set; }
    public string? Content { get; set; }
}
