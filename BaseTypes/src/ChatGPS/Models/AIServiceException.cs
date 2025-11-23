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

    public AIServiceException(Exception sourceException) : base(sourceException)
    {
    }

    public AIServiceException(string message, SerializableException innerException) : base(message, innerException)
    {
    }

    // This specific constructor is used to translate arbitrary exceptions, i.e.
    // those that don't inherity from SerializableException. This is how most
    // errors will be translated to the client side for error handling or display
    // to the user.
    public AIServiceException(string message, Exception sourceException) : base(message, sourceException)
    {
    }

    // This method is intended to be used for representing exceptions from proxy
    // commands.
    public static AIServiceException CreateServiceException(string message, Exception? innerException = null)
    {
        AIServiceException result;

        var serializableException = innerException is not null ? innerException as SerializableException : null;

        var targetException = serializableException ?? innerException;

        if ( targetException is not null )
        {
            result = new AIServiceException(message, targetException);
        }
        else
        {
            result = new AIServiceException(message);
        }

		return result;
    }

    public bool ExceededTokenLimit { get; set; }
    public int ThrottleRetryMsHint { get; set; }
}

