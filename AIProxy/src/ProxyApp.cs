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
        ProxyRequestException? requestException = null;

        if ( request is null || request.Content is null || request.CommandName is null || request.Content == String.Empty )
        {
            requestException = new ProxyRequestException(request, "Invalid request: the request was empty, had no content, or had no command name");
        }

        var commandContentType = requestException is null && request is not null && request.CommandName is not null ? CommandRequest.GetCommandRequestType(request.CommandName) : null;

        if ( requestException is null && commandContentType is null )
        {
            requestException = new ProxyRequestException(request, $"The specified command '{request?.CommandName}' does not have an associated request type");
        }

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        CommandRequest? commandContent = null;

        try
        {
            if ( requestException is null && request is not null && commandContentType is not null && request.Content is not null )
            {
                commandContent = (CommandRequest?) JsonSerializer.Deserialize(request.Content, commandContentType, jsonOptions);
            }
        }
        catch ( JsonException exception )
        {
            requestException = new ProxyRequestException(request, $"The specified command '{request?.CommandName}' is a valid command but its payload was invalid.", exception );
        }

        var encodedResponse = requestException is null && request is not null && request.CommandName is not null && commandContent is not null ?
            this.commandProcessor.InvokeCommand(request.RequestId, request.CommandName, commandContent, request.TargetConnectionId) :
            requestException?.ToEncodedErrorResponse() ?? "";

        finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

        Console.WriteLine(encodedResponse);

        return (finished, encodedResponse);
    }

    private int timeout;
    private CommandProcessor commandProcessor;
}

