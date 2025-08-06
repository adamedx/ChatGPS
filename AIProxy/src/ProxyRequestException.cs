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

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

public class ProxyRequestException : Exception
{
    public ProxyRequestException() {}

    public ProxyRequestException(ProxyRequest? request, string message, Exception? innerException = null ) : base("An invalid request was received by the proxy." + message, innerException )
    {
        this.Request = request;
    }

    public ProxyRequest? Request { get; set; }

    internal string? ToEncodedErrorResponse()
    {
        var requestId = this.Request?.RequestId ?? Guid.Empty;

        var resultException = AIServiceException.CreateServiceException(this.Message, this);

        var exceptions = new List<AIServiceException>();

        exceptions.Add(resultException);

        var noResponses = new string[0];

        var response = new ProxyResponse(requestId, ProxyResponse.ResponseStatus.Error, noResponses, exceptions.ToArray());

        return response.ToSerializedMessage();
    }
}
