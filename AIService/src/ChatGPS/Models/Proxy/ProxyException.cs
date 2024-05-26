//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models.Proxy;

public class ProxyException : Exception
{
    public ProxyException() {}

    // In general, exceptions cannot be safely serialized due to security concerns,
    // so we convert exceptions to an instance of this type that carries forward some
    // of the information about the inner exception, though it does not maintain the chain
    // of inner exceptions.
    public ProxyException(Exception? originalException = null) : base ( "The proxy service encountered an unexpected error." )
    {
        if ( originalException is not null )
        {
            this.OriginalExceptionTypeName = originalException.GetType().FullName;
            this.HelpLink = originalException.HelpLink;
            this.HResult = originalException.HResult;
            this.Source = originalException.Source;
            this.StackTrace = originalException.StackTrace;
            this.OriginalMessage = originalException.Message;
        }
    }

    public ProxyException(string message, ProxyException? proxyException = null) : base(message, proxyException)
    {
        InitializeFrom(proxyException);
    }

    public ProxyException(string message, Exception? innerException, ProxyException? proxyException = null) : base(message, innerException)
    {
        InitializeFrom(proxyException);
    }

    public override string ToString()
    {
        return $"{this.OriginalMessage}: {base.ToString()}";
    }

    private void InitializeFrom(ProxyException? proxyException)
    {
        if ( proxyException is not null )
        {
            this.StackTrace = proxyException.StackTrace;
            this.OriginalMessage = proxyException.OriginalMessage;
            this.OriginalExceptionTypeName = proxyException.OriginalExceptionTypeName;
        }
    }

    public new string? StackTrace { get; set; }
    public string? OriginalMessage { get; set; }
    public string? OriginalExceptionTypeName { get; set; }
}
