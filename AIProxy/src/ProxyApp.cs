//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

internal class ProxyApp
{
    internal ProxyApp(ServiceBuilder.ServiceId serviceId, AiOptions options, bool whatIfMode = false, bool encodedArguments = true, int timeout = 6000)
    {
        this.serviceId = serviceId;
        this.options = options;
        this.encodedArguments = encodedArguments;
        this.timeout = timeout;
        this.commandProcessor = new CommandProcessor(whatIfMode);
    }

    internal bool Run()
    {
        Logger.Log("Started proxy application");

        Initialize();

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

    private void Initialize()
    {
        Logger.Log($"Getting AI service with service id {serviceId}");

        var builder = ServiceBuilder.CreateBuilder();

        var chatService =  builder.WithServiceId(this.serviceId).WithOptions(this.options).Build();

        Logger.Log($"Successfully retrieved service");

        this.service = chatService;
    }

    private (bool finished, string? content) Responder(string input)
    {
        var argumentStart = input.IndexOf(" ");

        var commandName = argumentStart == -1 ?
            input :
            input.Substring(0, argumentStart);

        if ( commandName.Length == 0 )
        {
            throw new ArgumentException("No command name was specified");
        }

        var commandArguments = argumentStart != -1 ?
            input.Substring(argumentStart + 1, input.Length - argumentStart - 1) :
            null;

        var decodedArguments = this.encodedArguments ? ConvertBase64ToString(commandArguments) : commandArguments;

        var commandResult = this.commandProcessor.InvokeCommand(commandName, decodedArguments);

        var finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

        var encodedResponse = this.encodedArguments ? ConvertStringToBase64(commandResult) : commandResult;

        Console.WriteLine(encodedResponse);

        return (finished, commandResult);
    }

    private string? ConvertBase64ToString(string? base64String)
    {
        string? result = null;

        if ( base64String is not null )
        {
            var decodedBytes = Convert.FromBase64String(base64String);
            result = System.Text.Encoding.UTF8.GetString(decodedBytes);
        }

        return result;
    }

    private string? ConvertStringToBase64(string? unencodedString)
    {
        string? result = null;

        if ( unencodedString is not null )
        {
            var unencodedBytes = System.Text.Encoding.UTF8.GetBytes(unencodedString);
            result = Convert.ToBase64String(unencodedBytes);
        }

        return result;
    }

    private ServiceBuilder.ServiceId serviceId;
    private AiOptions options;
    private bool encodedArguments;
    private int timeout;
    private IChatService? service;
    private CommandProcessor commandProcessor;
}
