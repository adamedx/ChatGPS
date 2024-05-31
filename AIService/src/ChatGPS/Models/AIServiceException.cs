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
}
