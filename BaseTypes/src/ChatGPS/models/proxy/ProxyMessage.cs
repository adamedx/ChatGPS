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

namespace Modulus.ChatGPS.Models.Proxy;

public abstract class ProxyMessage
{
    static ProxyMessage()
    {
        ProxyMessage.jsonOptions = new JsonSerializerOptions();
        ProxyMessage.jsonOptions.IncludeFields = true;
    }

    public string? ToSerializedMessage()
    {
        var serialized = JsonSerializer.Serialize(this, this.GetType(), ProxyMessage.jsonOptions);

        return ConvertStringToBase64(serialized);
    }

    public static ProxyMessage FromSerializedMessage(string serializedMessage, Type targetType)
    {
        var decodedMessage = ConvertBase64ToString(serializedMessage);

        if ( decodedMessage is null )
        {
            throw new ArgumentException("The specified message was not a valid base64 string.");
        }

        var result = JsonSerializer.Deserialize(decodedMessage, targetType, ProxyMessage.jsonOptions);

        if ( result is null )
        {
            throw new ArgumentException("The message could not be deserialized");
        }

        return (ProxyMessage) result;
    }

    private static string? ConvertBase64ToString(string? base64String)
    {
        string? result = null;

        if ( base64String is not null )
        {
            var decodedBytes = Convert.FromBase64String(base64String);
            result = System.Text.Encoding.UTF8.GetString(decodedBytes);
        }

        return result;
    }

    private static string? ConvertStringToBase64(string? unencodedString)
    {
        string? result = null;

        if ( unencodedString is not null )
        {
            var unencodedBytes = System.Text.Encoding.UTF8.GetBytes(unencodedString);

            result = unencodedBytes is not null ? (Convert.ToBase64String(unencodedBytes) ?? null) : null;
        }

        return result;
    }

    protected static JsonSerializerOptions jsonOptions;
}

