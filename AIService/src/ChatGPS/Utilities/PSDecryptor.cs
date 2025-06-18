//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Security.Cryptography;

namespace Modulus.ChatGPS.Utilities;

internal class PSDecryptor
{
    internal static string GetDecryptedStringFromEncryptedUnicodeHexBytes(string encryptedString)
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
