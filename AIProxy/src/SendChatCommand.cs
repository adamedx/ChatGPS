//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using System.Collections.Generic;
using Microsoft.SemanticKernel.ChatCompletion;

using Modulus.ChatGPS.Models.Proxy;

internal class SendChatCommand : Command
{
    internal SendChatCommand(CommandProcessor processor) : base(processor) {}

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

        var connection = this.processor.Connections.GetConnection(this.arguments.ConnectionId);

        var task = connection.ChatService.GetChatCompletionAsync(this.arguments.History);

        var result = task.Result;

        var response = new SendChatResponse( ( result is not null ) ? result[result.Count - 1].Content : null );

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        return JsonSerializer.Serialize<SendChatResponse>(response, jsonOptions);
    }

    private SendChatRequest? arguments;
}
