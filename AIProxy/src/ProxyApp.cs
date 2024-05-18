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
    internal ProxyApp(int timeout = 6000, bool whatIfMode = false, bool encodedArguments = true)
    {
        this.encodedArguments = encodedArguments;
        this.timeout = timeout;
        this.commandProcessor = new CommandProcessor(whatIfMode);
    }

    internal bool Run()
    {
        Logger.Log("Started proxy application");

        var listener = new Modulus.ChatGPS.AIProxy.Listener(Responder);

        CancellationTokenSource cancellationSource = new CancellationTokenSource();

        bool finished;

        try
        {
            listener.Start( cancellationSource );

            finished = listener.Wait(this.timeout);

            listener.Stop();
        }
        finally
        {
            cancellationSource.Dispose();
        }

        Logger.Log("Finished proxy application");

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
        string? encodedResponse = null;

        var decodedRequest = ConvertBase64ToString(encodedRequest);

        if ( decodedRequest is not null )
        {
            var jsonOptions = new JsonSerializerOptions();
            jsonOptions.IncludeFields = true;

            var request = JsonSerializer.Deserialize<ProxyRequest>(decodedRequest, jsonOptions);

            if ( request is null || request.Content is null || request.CommandName is null )
            {
                throw new ArgumentException("Invalid request: the request was empty, had no content, or had no command name");
            }

            var commandContentType = CommandRequest.GetCommandRequestType(request.CommandName);

            if ( commandContentType is null )
            {
                throw new ArgumentException($"The specified command '{request.CommandName}' does not have an associated request type");
            }

            var commandContent = (CommandRequest?) JsonSerializer.Deserialize(request.Content, commandContentType, jsonOptions);

            var commandResult = this.commandProcessor.InvokeCommand(request.RequestId, request.CommandName, commandContent, request.TargetConnectionId);

            finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

            encodedResponse = ConvertStringToBase64(commandResult);

            Console.WriteLine(encodedResponse);
        }

        return (finished, encodedResponse);
    }

    private string? ConvertBase64ToString(string? base64String)
    {
        string? result = null;

        if ( this.encodedArguments )
        {
            if ( base64String is not null )
            {
                var decodedBytes = Convert.FromBase64String(base64String);
                result = System.Text.Encoding.UTF8.GetString(decodedBytes);
            }
        }
        else
        {
            result = base64String;
        }

        return result;
    }

    private string? ConvertStringToBase64(string? unencodedString)
    {
        string? result = null;

        if ( this.encodedArguments )
        {
            if ( unencodedString is not null )
            {
                var unencodedBytes = System.Text.Encoding.UTF8.GetBytes(unencodedString);
                result = Convert.ToBase64String(unencodedBytes);
            }
        }
        else
        {
            result = unencodedString;
        }

        return result;
    }

    private bool encodedArguments;
    private int timeout;
    private CommandProcessor commandProcessor;
}
