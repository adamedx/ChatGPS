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

using System.Security.Cryptography;

namespace Modulus.ChatGPS.Utilities;

public class PSDecryptor
{
    public static string GetDecryptedStringFromEncryptedUnicodeHexBytes(string encryptedString)
    {
        // Ensure that on non-Windows platforms we do not execute this method by throwing an
        // exception. This also avoids compiler warning CA1416.
        if ( ! OperatingSystem.IsWindows() )
        {
            throw new PlatformNotSupportedException("Encryption support is not available for this platform; it is only available for the Windows platform.");
        }

        if ( ( encryptedString.Length % 2 ) != 0 )
        {
            throw new ArgumentException("The specified string format is invalid -- it must contain an even number of characters, all of which must be hexadecimal digits");
        }

        var encryptedBytes = new byte[encryptedString.Length / 2];
        var currentByteCharacters = new char[2];
        int destination = 0;

        for ( var source = 0; source < encryptedString.Length; source += 2 )
        {
            currentByteCharacters[0] = encryptedString[source];
            currentByteCharacters[1] = encryptedString[source + 1];
            encryptedBytes[destination++] = Convert.ToByte(new string(currentByteCharacters), 16);
        }

        var decryptedBytes = ProtectedData.Unprotect(encryptedBytes, null, DataProtectionScope.CurrentUser);

        // This MUST be unicode -- apparently the serialized output uses unicode
        var result = System.Text.Encoding.Unicode.GetString(decryptedBytes);

        return result;
    }
}

