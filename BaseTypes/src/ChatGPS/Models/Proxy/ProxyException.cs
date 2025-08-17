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

namespace Modulus.ChatGPS.Models.Proxy;

public class ProxyException : SerializableException
{
    public enum ExceptionType
    {
        BadConnection
    }

    public ProxyException() {}

    public ProxyException(string message, (string key, object value)[]? pairs ) : base ( message, pairs ) {}

    public ProxyException(AIServiceException targetServiceException) : base (targetServiceException)
    {
        this.TargetServiceException = targetServiceException;
    }

    public ProxyException(Exception originalException) : base (originalException) {}

    public ProxyException(string message, SerializableException? SerializableException = null) : base(message, SerializableException) {}

    public ProxyException(string message, Exception? innerException, SerializableException? SerializableException = null) : base(message, innerException) {}

    public AIServiceException? TargetServiceException { get; set; }
}

