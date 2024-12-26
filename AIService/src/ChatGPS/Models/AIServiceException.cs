//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using System.Text.Json.Nodes;

namespace Modulus.ChatGPS.Models;

public class AIServiceException : SerializableException
{
    public AIServiceException() {}

    public AIServiceException(string message) : base (message) {}

    public AIServiceException(Exception? sourceException) : base(sourceException)
    {
        InitializeThrottleInformation(sourceException);
        InitializeTokenLimit(sourceException);
    }

    public AIServiceException(string message, SerializableException innerException) : base(message, innerException)
    {
        InitializeTokenLimit(innerException);
    }

    public static AIServiceException CreateServiceException(string message, Exception? innerException = null)
    {
        AIServiceException result;

        var targetException = innerException is not null ? innerException as SerializableException : null;

        if ( targetException is not null )
        {
            result = new AIServiceException(message, targetException);
        }
        else
        {
            result = new AIServiceException(message);
        }

        result.InitializeTokenLimit(innerException);

        return result;
    }

    private void InitializeTokenLimit(Exception? sourceException)
    {
        var serviceException = sourceException is not null ? sourceException as AIServiceException : null;

        this.ExceededTokenLimit = serviceException is not null ?
            serviceException.ExceededTokenLimit :
            IsTokenLimitException(sourceException as Microsoft.SemanticKernel.HttpOperationException );
    }

    private void InitializeThrottleInformation(Exception? sourceException)
    {
        this.ThrottleRetryMsHint = 0;

        if ( sourceException is not null )
        {
            var httpException = sourceException as Microsoft.SemanticKernel.HttpOperationException;

            if ( httpException is not null && httpException.StatusCode == System.Net.HttpStatusCode.TooManyRequests )
            {
                // Currently the HttpOperation class in SemanticKernel does not inherit from a standard http
                // exception, and it is missing key properties such as the complete response, which contains
                // the headers. The retry value is actually found in the `retry-after` header, so the fact that the
                // exception exposes no headers and does not otherwise surface this value as a property means we just...
                // guess at a time out. The actual error handling code can (and probably should) treat this value as a
                // hint and add additional heuristics for reliability until this limitation is fixed.
                this.ThrottleRetryMsHint = 15000;
            }
        }
    }

    private bool IsTokenLimitException( Microsoft.SemanticKernel.HttpOperationException? operationException )
    {
        var tokenLimitExceeded = false;

        if ( operationException is not null && operationException.ResponseContent is not null )
        {
            var responseContent = operationException.ResponseContent;

            JsonNode? jsonNode = null;

            try
            {
                jsonNode = JsonNode.Parse(responseContent);
            }
            catch
            {
            }

            string? responseCode = null;

            if ( ( jsonNode != null ) && jsonNode["error"]!["code"]!.AsValue().TryGetValue<string>( out responseCode ) )
            {
                if ( responseCode == "context_length_exceeded" )
                {
                    tokenLimitExceeded = true;
                }
            }
        }

        return tokenLimitExceeded;
    }

    public bool ExceededTokenLimit { get; set; }
    public int ThrottleRetryMsHint { get; set; }
}
