#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Get-ChatEncryptedUnicodeKeyCredential {
    [cmdletbinding(positionalbinding=$false)]
    param()

    if ( ! ( $PSVersionTable.Platform -eq 'Win32NT' ) ) {
        throw [System.PlatformNotSupportedException]::new("Encryption is not supported on this platform; it is only supported on the Windows platform")
    }

    $encryptedKey = Read-Host 'ChatGPS: Enter secret key / password>' -AsSecureString

    # This will output a sequence of hex digits representing the string --
    # each pair of digits is a byte of the string, which is actually
    # (always I hope!!?) encoded as unicode.
    $encryptedKey | ConvertFrom-SecureString
}
