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
        InitializeThrottleInformation(innerException);
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
        result.InitializeThrottleInformation(innerException);

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
        var serviceException = sourceException is not null ? sourceException as AIServiceException : null;

        this.ThrottleRetryMsHint = serviceException is not null ?
            serviceException.ThrottleRetryMsHint : GetThrottleRetryHint( sourceException as Microsoft.SemanticKernel.HttpOperationException );
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

            if ( jsonNode is not null )
            {
                var codeNode = jsonNode["error"]!["code"];

                if ( ( codeNode is not null ) && codeNode.AsValue().TryGetValue<string>( out responseCode ) )
                {
                    if ( responseCode == "context_length_exceeded" )
                    {
                        tokenLimitExceeded = true;
                    }
                }
            }
        }

        return tokenLimitExceeded;
    }

    private int GetThrottleRetryHint(Microsoft.SemanticKernel.HttpOperationException? operationException)
    {
        int retryMsHint = 0;

        if ( operationException is not null && operationException.StatusCode == System.Net.HttpStatusCode.TooManyRequests )
        {
            // Currently the HttpOperation class in SemanticKernel does not inherit from a standard http
            // exception, and it is missing key properties such as the complete response, which contains
            // the headers. The retry value is actually found in the `retry-after` header, so the fact that the
            // exception exposes no headers and does not otherwise surface this value as a property means we just...
            // guess at a time out. The actual error handling code can (and probably should) treat this value as a
            // hint and add additional heuristics for reliability until this limitation is fixed.
            retryMsHint = 15000;
        }

        return retryMsHint;
    }


    public bool ExceededTokenLimit { get; set; }
    public int ThrottleRetryMsHint { get; set; }
}

