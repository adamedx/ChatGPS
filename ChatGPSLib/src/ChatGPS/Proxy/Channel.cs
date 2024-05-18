//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using Modulus.ChatGPS.OS;

namespace Modulus.ChatGPS.Proxy;

internal class Channel
{
    internal Channel(int idleTimeoutMs)
    {
        this.process = new Process(new TimeSpan(0, 0, 0, 0, idleTimeoutMs));
    }
/*
    internal async Task SendMessageAsync(string message)
    {
        throw new NotImplementedException();
    }

    internal async Task<string> ReadMessageAsync()
    {
        throw new NotImplementedException();
    }
*/

    Process process;
}
