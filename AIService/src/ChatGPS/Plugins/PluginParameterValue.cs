//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using Modulus.ChatGPS.Utilities;

namespace Modulus.ChatGPS.Plugins;

public class PluginParameterValue
{
    public PluginParameterValue()
    {
        this.deserializedValue = null;
        this.serializedValue = null;
        this.typeName = null;
        this.encrypted = null;
    }

    public PluginParameterValue(object? value, bool encrypted = false)
    {
        SetValue(value, encrypted);
    }

    public string? SerializedValue
    {
        get
        {
            return this.serializedValue;
        }

        set
        {
            this.serializedValue = value;
        }
    }

    public bool Encrypted
    {
        get
        {
            return this.encrypted == true;
        }

        set
        {
            if ( this.encrypted is not null )
            {
                throw new InvalidOperationException("The 'Encrypted' property of a parameter value object may not be changed after it is set.");
            }

            if ( value && ( this.typeName is not null && this.typeName == typeof(string).FullName ) )
            {
                throw new InvalidOperationException($"The 'Encrypted' property of a parameter value of type {this.typeName} cannot be set to 'true' because encryption is only supported for parameters of type System.String.");
            }

            this.encrypted = value;
        }
    }

    public string? TypeName
    {
        get
        {
            return this.typeName;
        }

        set
        {
            if ( this.typeName is null )
            {
                if ( value is not null && this.Encrypted && value != typeof(string).FullName )
                {
                    throw new InvalidOperationException($"The 'Encrypted' property of the parameter value object is set to true, so the 'TypeName' property of value {value} is not valid for the object because a encryption is only supported for parameters of type System.String");
                }
                this.typeName = value;
            }
            else
            {
                throw new InvalidOperationException("The value's type may not be changed after it is set.");
            }
        }
    }

    public object? GetValue()
    {
        if ( this.deserializedValue is null && this.serializedValue is not null )
        {
            SetValueFromSerializedValue();
        }

        return this.deserializedValue;
    }

    public object? GetDecryptedValue()
    {
        var encryptedValue = GetValue();

        var result = encryptedValue;

        if ( this.Encrypted )
        {
            if ( this.typeName != typeof(string).FullName )
            {
                throw new InvalidOperationException($"The value of type {this.typeName} is encrypted but decryption only supported for values of type System.String.");
            }

            if ( encryptedValue is not null )
            {
                result = PSDecryptor.GetDecryptedStringFromEncryptedUnicodeHexBytes( (string) encryptedValue );
            }
        }

        return result;
    }

    public void SetValue(object? value, bool encrypted = false)
    {
        SetValueFromDeserializedValue(value, encrypted);
    }

    private void SetValueFromDeserializedValue(object? deserializedValue, bool encrypted = false)
    {
        string? serializedValue = null;
        Type? type = null;

        if ( deserializedValue is not null )
        {
            var jsonOptions = new JsonSerializerOptions();

            type = deserializedValue.GetType();

            serializedValue = JsonSerializer.Serialize(deserializedValue, type);
        }

        this.deserializedValue = deserializedValue;
        this.serializedValue = serializedValue;
        this.typeName = type?.FullName;
        this.encrypted = encrypted && this.typeName == typeof(string).FullName;
    }

    private void SetValueFromSerializedValue()
    {
        if ( this.typeName is null )
        {
            throw new InvalidOperationException("The value cannot be updated from serialized data because its intended type is not set.");
        }

        object? deserializedValue = null;

        if ( serializedValue is not null )
        {
            var jsonOptions = new JsonSerializerOptions();

            deserializedValue = JsonSerializer.Deserialize(serializedValue, serializedValue.GetType());
        }

        this.deserializedValue = deserializedValue;
    }

    private object? deserializedValue;
    private string? serializedValue;
    private string? typeName;
    private bool? encrypted;
}
