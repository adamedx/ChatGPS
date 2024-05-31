//
// Copyright (c), Adam Edwards
//
// All rights reserved.
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

    public ProxyException(Exception? originalException = null) : base (originalException) {}

    public ProxyException(string message, SerializableException? SerializableException = null) : base(message, SerializableException) {}

    public ProxyException(string message, Exception? innerException, SerializableException? SerializableException = null) : base(message, innerException) {}

    public AIServiceException? TargetServiceException { get; set; }
}
