//
// Copyright (c) Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;

using Modulus.ChatGPS.Communication;
using Modulus.ChatGPS.Models.Proxy;

namespace Modulus.ChatGPS.Proxy;

internal class Transport
{
    internal Transport()
    {
        this.pendingRequests = new Dictionary<Guid,(ProxyRequest Request, ProxyResponse Response)>();
    }

    internal async Task<ProxyResponse> SendAsync(ProxyConnection connection, ProxyRequest requestMessage)
    {
        var maxAttempts = 2;
        ProxyResponse? result = null;

        for ( int attempt = 0; attempt < maxAttempts; attempt++ )
        {
            try
            {
                result = await SendAsyncNoRetry(connection, requestMessage);

                if ( result.Status == ProxyResponse.ResponseStatus.Error )
                {
                    if ( ( result.Exceptions is not null && result.Exceptions.Length > 0 ) &&
                         ( result.Exceptions[0].Properties is not null ) )
                    {
                        var properties = result.Exceptions[0].Properties;
                        if ( properties is not null )
                        {
                            if ( properties.ContainsKey( ProxyException.ExceptionType.BadConnection.ToString() ) )
                            {
                                connection.ResetTargetServiceBinding();
                                continue;
                            }
                        }
                    }
                }

                break;
            }
            catch
            {
                if ( attempt == maxAttempts - 1 )
                {
                    throw;
                }
            }
        }

        if ( result is null )
        {
            throw new ProxyException("An unexpected error occurred sending a message to the AI Proxy");
        }

        return result;
    }

    private async Task<ProxyResponse> SendAsyncNoRetry(ProxyConnection connection, ProxyRequest requestMessage)
    {
        await connection.SendRequestAsync(requestMessage);

        ProxyResponse result;

        (ProxyRequest request, ProxyResponse response) pendingRequest;

        try
        {
            while (true)
            {
                // Wait for a response from the proxy
                var response = await connection.ReadResponseAsync();

                // If this response matches the request we're processing, we're done!
                if ( response.RequestId == requestMessage.RequestId )
                {
                    result = response;
                    break;
                }

                // The response we received above is not the one we're looking for, let's see
                // if it's already been updated in the pending request list -- if it's not
                // we'll just repeat the previous steps to wait for another response that might
                // be the one we're looking for.
                lock ( this.pendingRequests )
                {
                    // Is the request already in hte list of pending requests?
                    if ( this.pendingRequests.TryGetValue(requestMessage.RequestId, out pendingRequest) )
                    {
                        // If it's here and it has a response, return it, we have found what we're
                        // looking for and we can return the response and break out of the loop
                        // that is repeatedly waiting for a response.
                        if ( pendingRequest.response is not null )
                        {
                            result = pendingRequest.response;
                            break;
                        }
                    }
                    else
                    {
                        // The request isn't found in the pending list of requests, so add it there
                        // so we can repeat previous steps and wait for a response to it
                        this.pendingRequests.Add(pendingRequest.request.RequestId, pendingRequest);
                    }
                }
            }
        }
        finally
        {
            // Exiting this method means either that the search was successful or we've given up
            // on it due to an exception, so remove it from the list of pending requests if it's done.
            lock ( this.pendingRequests )
            {
                if ( this.pendingRequests.ContainsKey(requestMessage.RequestId) )
                {
                    this.pendingRequests.Remove(requestMessage.RequestId);
                }
            }
        }

        return result;
    }

    private Dictionary<Guid,(ProxyRequest Request, ProxyResponse Response)> pendingRequests;
}
