//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//


using System.Text.Json;

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;
using Modulus.ChatGPS.Services;

internal class ProxyApp
{
    internal ProxyApp(int timeout = 60000, bool whatIfMode = true)
    {
        this.timeout = timeout;
        this.commandProcessor = new CommandProcessor(whatIfMode);
    }

    internal bool Run()
    {
        Logger.Log("Started proxy application");

        var listener = new Modulus.ChatGPS.AIProxy.Listener(Responder);

        bool finished;

        try
        {
            listener.Start();

            finished = listener.Wait(this.timeout);

            listener.Stop();
        }
        catch ( Exception exception )
        {
            Logger.Log("***********************************");
            Logger.Log("***** UNHANDLED EXCEPTION!!! ******");
            Logger.Log($"***** {exception.GetType().FullName}");
            Logger.Log($"***** {exception.Message}");
            Logger.Log(exception.StackTrace ?? "No stack trace available.");
            Logger.Log("***********************************");

            throw;
        }
        finally
        {
            Logger.Log("Finished proxy application");
        }

        return finished;
    }

    internal bool WhatIfMode {
        get
        {
            return this.commandProcessor.WhatIfMode;
        }
    }

    private (bool finished, string? content) Responder(string encodedRequest)
    {
        var finished = false;
        var request = (ProxyRequest) ProxyRequest.FromSerializedMessage(encodedRequest, typeof(ProxyRequest));

        if ( request is null || request.Content is null || request.CommandName is null )
        {
            throw new ArgumentException("Invalid request: the request was empty, had no content, or had no command name");
        }

        var commandContentType = CommandRequest.GetCommandRequestType(request.CommandName);

        if ( commandContentType is null )
        {
            throw new ArgumentException($"The specified command '{request.CommandName}' does not have an associated request type");
        }

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        var commandContent = (CommandRequest?) JsonSerializer.Deserialize(request.Content, commandContentType, jsonOptions);

        var encodedResponse = this.commandProcessor.InvokeCommand(request.RequestId, request.CommandName, commandContent, request.TargetConnectionId);

        finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

        Console.WriteLine(encodedResponse);

        return (finished, encodedResponse);
    }

    private int timeout;
    private CommandProcessor commandProcessor;
}
