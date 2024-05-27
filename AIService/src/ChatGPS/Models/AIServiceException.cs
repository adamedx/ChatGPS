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

    public AIServiceException(Exception? sourceException) : base(sourceException) {}

    public AIServiceException(string message, SerializableException? innerException) : base(message, innerException)
    {
        InitializeTokenLimit(innerException);
    }

    // Will take relevant information from the serializable exception in preference to the more generic inner exception if
    // both are specified
    public AIServiceException(string message, Exception? innerException, SerializableException? sourceException = null) : base(message, null)
    {
        InitializeTokenLimit(sourceException ?? innerException);
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
