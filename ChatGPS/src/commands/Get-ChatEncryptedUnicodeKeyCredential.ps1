#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function Get-ChatEncryptedUnicodeKeyCredential {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(ValueFromPipeline=$true)]
        [string] $PlainText = $null
    )

    if ( ! ( $PSVersionTable.Platform -eq 'Win32NT' ) ) {
        throw [System.PlatformNotSupportedException]::new("Encryption is not supported on this platform; it is only supported on the Windows platform")
    }

    $encryptedKey = if ( $plainText ) {
        $plainText | ConvertTo-SecureString -AsPlainText
    } else {
        Read-Host 'ChatGPS: Enter secret key / password>' -AsSecureString
    }

    # This will output a sequence of hex digits representing the string --
    # each pair of digits is a byte of the string, which is actually
    # (always I hope!!?) encoded as unicode.
    $encryptedKey | ConvertFrom-SecureString
}
