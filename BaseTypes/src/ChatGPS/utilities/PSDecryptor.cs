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
    // The format of "Unicode Hex Bytes" assumed as input to this function is chosen because it is already
    // utilized commonly in PowerShell. For example this encrypted format is what you get when you pass a plain text
    // string as input to the ConvertTo-SecureString PowerShell command with the AsPlainText option, or when
    // the Read-Host PowerShell command is used with its AsSecureString parameter, or the combination of the Password
    // property on the output of Get-Credential passed to the ConvertFrom-SecureString command. An example of PowerShell
    // code that produces such an encrypted string is as follows:
    //
    // # EXAMPLE 1
    // # Interactively enter a password via Read-Host
    // $encryptedPassword = Read-Host -AsSecureString # This returns a System.Security.SecureString type
    // $unicodeHexBytesEncryptedString = $encryptedPassword | ConvertFrom-SecureString
    //
    // # EXAMPLE 2
    // $plainTextPassword = Get-PlainTextFromSomewhereMaybeAFile
    // $encryptedPassword = $plainTextPassword | ConvertTo-SecureString -AsPlainText
    // $unicodeHexBytesEncryptedString = $encryptedPassword | ConvertFrom-SecureString
    //
    // # EXAMPLE 3
    // # Interactively enter a password via Get-Credential
    // $credential = Get-Credential -user anytext # -user parameter can be anything
    // $encryptedPassword = $credential.Password # Returns a System.Security.SecureString type
    // $unicodeHexBytesEncryptedString = $encryptedPassword | ConvertFrom-SecureString
    //
    // Ultimately the Get-Credential, Read-Host -AsSecure, and Convert-ToSecureString PowerShell commands
    // all encrypt data using the Windows data protection API's CryptProtectData API -- decryption
    // is then accomplished with the CryptUnprotectData Windows API. .NET's ProtectData
    // implementation only supports this Windows API implementation and does not provide this functionality for
    // other operating systems, so this function is limited to Windows only for now unfortunately.
    //
    // That said, this format is common within the PowerShell ecosystem which is still heavily Windows-based
    // at this point anyway, so the idea is that this is a reasonable tradeoff between usability and portability.
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

