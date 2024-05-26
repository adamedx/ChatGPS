//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

public class SerializableException : Exception
{
    public SerializableException() {}

    // In general, exceptions cannot be safely serialized due to security concerns,
    // so we convert exceptions to an instance of this type that carries forward some
    // of the information about the inner exception, though it does not maintain the chain
    // of inner exceptions.
    public SerializableException(Exception? originalException = null) : base ( "An unexpected error was encountered." )
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

    public SerializableException(string message, SerializableException? SerializableException = null) : base(message, SerializableException)
    {
        InitializeFrom(SerializableException);
    }

    public SerializableException(string message, Exception? innerException, SerializableException? SerializableException = null) : base(message, innerException)
    {
        InitializeFrom(SerializableException);
    }

    public override string ToString()
    {
        return $"{this.OriginalMessage}: {base.ToString()}";
    }

    private void InitializeFrom(SerializableException? SerializableException)
    {
        if ( SerializableException is not null )
        {
            this.StackTrace = SerializableException.StackTrace;
            this.OriginalMessage = SerializableException.OriginalMessage;
            this.OriginalExceptionTypeName = SerializableException.OriginalExceptionTypeName;
        }
    }

    public new string? StackTrace { get; set; }
    public string? OriginalMessage { get; set; }
    public string? OriginalExceptionTypeName { get; set; }
}
