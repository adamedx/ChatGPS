//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

public class SerializableException : Exception
{
    public SerializableException() {
        this.Properties = new Dictionary<string,object>();
    }

    // In general, exceptions cannot be safely serialized due to security concerns,
    // so we convert exceptions to an instance of this type that carries forward some
    // of the information about the inner exception, though it does not maintain the chain
    // of inner exceptions.

    // This extracts serializable data from the sourceException but keeps innerException null
    protected SerializableException(Exception? originalException = null) : base ( "An unexpected error was encountered." )
    {
        InitializeFromException(originalException);
    }

    protected SerializableException(string message, (string key, object value)[]? pairs ) : base ( message)
    {
        InitializeFromException(null, pairs);
    }

    // This allows the inner exception to be set since it is known to be serializable. It also promotes serializable
    // properties of the inner exception to the newly constructed instance
    protected SerializableException(string message, SerializableException? serializableInnerException = null) : base(message)
    {
        InitializeFromException(serializableInnerException);
    }

    // This allows setting the inner exception, but will extract some information
    // from it and make that accessible via public properties
    protected SerializableException(string message, Exception? innerException, SerializableException? serializableException = null) : base(message)
    {
        Exception? targetException = innerException ?? serializableException;

        if ( targetException is not null )
        {
            InitializeFromException(targetException);
        }
    }

    public override string ToString()
    {
        return $"{this.OriginalMessage}: {base.ToString()}";
    }

    private void InitializeFrom(SerializableException? serializableException)
    {
        if ( serializableException is not null )
        {
            this.StackTrace = serializableException.StackTrace;
            this.OriginalMessage = serializableException.OriginalMessage;
            this.OriginalExceptionTypeName = serializableException.OriginalExceptionTypeName;
        }
    }

    private void InitializeFromException(Exception? originalException, (string key,object value)[]? pairs = null)
    {
        SerializableException? serializableException = null;

        if ( originalException is SerializableException )
        {
            serializableException = (SerializableException) originalException;
            InitializeFrom(serializableException);
        }
        else if ( originalException is not null )
        {
            this.OriginalExceptionTypeName = originalException.GetType().FullName;
            this.HelpLink = originalException.HelpLink;
            this.HResult = originalException.HResult;
            this.Source = originalException.Source;
            this.StackTrace = originalException.StackTrace;
            this.OriginalMessage = originalException.Message;
        }

        this.Properties = new Dictionary<string,object>();

        if ( serializableException is not null && serializableException.Properties is not null )
        {
            foreach ( var key in serializableException.Properties.Keys )
            {
                this.Properties.Add(key, serializableException.Properties[key]);
            }
        }

        if ( pairs is not null )
        {
            foreach ( var pair in pairs )
            {
                this.Properties.Add(pair.key, pair.value);
            }
        }
    }

    public new string? StackTrace { get; set; }
    public string? OriginalMessage { get; set; }
    public string? OriginalExceptionTypeName { get; set; }
    public Dictionary<string,object>? Properties {get; set; }
}
