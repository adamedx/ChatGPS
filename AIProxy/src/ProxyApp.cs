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

        string? encodedResponse = null;

        try
        {
            var requestParameters = GetRequestParameters(request);

            encodedResponse = this.commandProcessor.InvokeCommand(
                requestParameters.requestId,
                requestParameters.commandName,
                requestParameters.commandRequest,
                requestParameters.targetConnectionId);
        }
        catch ( ProxyRequestException requestException )
        {
            encodedResponse = requestException.ToEncodedErrorResponse();
        }

        finished = commandProcessor.Status == CommandProcessor.RuntimeStatus.Exited;

        Console.WriteLine(encodedResponse);

        return (finished, encodedResponse);
    }

    (Guid requestId, string commandName, CommandRequest commandRequest, Guid targetConnectionId) GetRequestParameters(ProxyRequest? request)
    {
        ProxyRequest proxyRequest;
        string requestContent;
        string commandName;

        if ( request is not null && request.Content is not null && request.CommandName is not null && request.Content != String.Empty )
        {
            proxyRequest = request;
            requestContent = request.Content;
            commandName = request.CommandName;
        }
        else
        {
            throw new ProxyRequestException(request, "Invalid request: the request was empty, had no content, or had no command name");
        }

        var commandContentType = CommandRequest.GetCommandRequestType(commandName);

        if ( commandContentType is null )
        {
            throw new ProxyRequestException(proxyRequest, $"The specified command '{request?.CommandName}' does not have an associated request type");
        }

        var jsonOptions = new JsonSerializerOptions();
        jsonOptions.IncludeFields = true;

        CommandRequest? commandRequest = null;

        try
        {
            if ( request is not null && commandContentType is not null && request.Content is not null )
            {
                var deserializedContent = (CommandRequest?) JsonSerializer.Deserialize(request.Content, commandContentType, jsonOptions);

                if ( deserializedContent is not null )
                {
                    commandRequest = deserializedContent;
                }
            }
        }
        catch ( JsonException exception )
        {
            throw new ProxyRequestException(request, $"The specified command '{request?.CommandName}' is a valid command but its payload was invalid.", exception );
        }

        if ( commandRequest is null )
        {
            throw new ProxyRequestException(request, $"The specified command '{request?.CommandName}' is a valid command but its payload was deserialized as empty.");
        }

        return (proxyRequest.RequestId, commandName, commandRequest, proxyRequest.TargetConnectionId);
    }

    private int timeout;
    private CommandProcessor commandProcessor;
}

