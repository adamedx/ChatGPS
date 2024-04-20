//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

internal class ProxyApp
{
    internal ProxyApp(ServiceBuilder.ServiceId serviceId, AiOptions options, int timeout = 6000)
    {
        this.serviceId = serviceId;
        this.options = options;
        this.timeout = timeout;
        this.commandProcessor = new CommandProcessor();
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
        string responseContent;

        responseContent = $"Received request: {input}.";

        try
        {
            var inputParameters = input.Split(" ");

            if ( inputParameters.Length == 0 )
            {
                throw new ArgumentException("No command name was specified");
            }

            var commandName = inputParameters[0];

            var commandArguments = new string[inputParameters.Length - 1];

            if ( inputParameters.Length > 1 )
            {
                commandArguments[0] = inputParameters[1];
            }

            var commandResult = this.commandProcessor.InvokeCommand(commandName, commandArguments);

            responseContent += $" SUCCESS: {commandResult}";
        }
        catch (ArgumentException e)
        {
            responseContent += $" ERROR: {e.Message}";
        }

        var finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

        Console.WriteLine("RESPONSE: {0}", responseContent ?? "(no content)");

        return (finished, responseContent);
    }

    private ServiceBuilder.ServiceId serviceId;
    private AiOptions options;
    private int timeout;
    private IChatService? service;
    private CommandProcessor commandProcessor;
}
