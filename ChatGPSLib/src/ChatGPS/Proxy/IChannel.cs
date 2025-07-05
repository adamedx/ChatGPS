//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Communication;

interface IChannel
{
    Task SendMessageAsync(string message);

    Task<string?> ReadMessageAsync();

    void Reset();
}
