//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

interface IChannel
{
    Task SendMessageAsync(string message);

    Task<string> ReadMessageAsync();

    void Reset();
}
