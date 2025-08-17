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

namespace Modulus.ChatGPS.Models;

public class SerializableException : Exception
{
    public SerializableException()
    {
        this.Properties = new Dictionary<string,object>();
    }

    public SerializableException(string message) : base(message)
    {
        this.OriginalMessage = message;
        this.Properties = new Dictionary<string,object>();
    }

    // In general, exceptions cannot be safely serialized due to security concerns,
    // so we convert exceptions to an instance of this type that carries forward some
    // of the information about the inner exception, though it does not maintain the chain
    // of inner exceptions.

    // This extracts serializable data from the sourceException but keeps innerException null
    protected SerializableException(Exception? originalException = null) : base ( "An unexpected error was encountered." )
    {
        this.OriginalMessage = this.Message;
        InitializeFromException(originalException);
    }

    protected SerializableException(string message, (string key, object value)[]? pairs ) : base ( message)
    {
        this.OriginalMessage = message;
        InitializeFromException(null, pairs);
    }

    // This allows the inner exception to be set since it is known to be serializable. It also promotes serializable
    // properties of the inner exception to the newly constructed instance
    protected SerializableException(string message, SerializableException? serializableInnerException = null) : base(message)
    {
        this.OriginalMessage = message;
        InitializeFromException(serializableInnerException);
    }

    // This allows setting the inner exception, but will extract some information
    // from it and make that accessible via public properties
    protected SerializableException(string message, Exception? innerException, SerializableException? serializableException = null) : base(message)
    {
        this.OriginalMessage = message;

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

    public override string Message
    {
        get
        {
            return ( ( ( this.OriginalMessage is not null ) && this.OriginalMessage.Length > 0 ) ? this.OriginalMessage : this.Message ) ?? "";
        }
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

