//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Utilities;

public class PSEncryptedString
{
    public PSEncryptedString () { this.EncryptedValue = ""; }

    public PSEncryptedString(string encryptedValue)
    {
        this.EncryptedValue = encryptedValue;
    }

    public string EncryptedValue { get; set; }
}
