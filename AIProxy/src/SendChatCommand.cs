//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using Microsoft.SemanticKernel.ChatCompletion;

using Modulus.ChatGPS.Models.Proxy;

internal class SendChatCommand : Command
{
    internal SendChatCommand(CommandProcessor processor) : base(processor) {}

    internal override ProxyResponse.Operation[] Process(string? arguments, bool whatIf = false)
    {
        var operation = new ProxyResponse.Operation("sendchat", Invoke);

        this.arguments = ( arguments is not null ) ? JsonSerializer.Deserialize<SendChatRequest>(arguments) : null;

        if ( this.arguments is null )
        {
            throw new ArgumentException("Invalid arguments specified for chat command");
        }

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

        var connection = this.processor.Connections.GetConnection(this.arguments.ConnectionId);

        var task = connection.ChatCompletion.GetChatMessageContentsAsync(this.arguments.History);

        var result = task.Result;

        var response = new SendChatResponse( ( result is not null ) ? result[result.Count - 1].Content : null );

        return JsonSerializer.Serialize<SendChatResponse>(response);
    }

    private SendChatRequest? arguments;
}
