//
// Copyright (c) Adam Edwards
//
// All rights reserved.
//

using System.IO;

using Modulus.ChatGPS.OS;

namespace Modulus.ChatGPS.Communication;

public abstract class StdioChannel : IChannel
{
    public StdioChannel(string? commandPath = null)
    {
        this.commandPath = commandPath;
    }

    public virtual async Task SendMessageAsync(string message)
    {
        InitializeChannel();

        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        await this.process.WriteLineAsync(message);

        return;
    }

    protected void SetExecutablePath(string commandPathValue)
    {
        if ( this.commandPath != null )
        {
            throw new InvalidOperationException("The command host path is already set and may not be set again.");
        }

        this.commandPath = commandPathValue;
    }

    public virtual async Task<string?> ReadMessageAsync()
    {
        if ( this.process is null )
        {
            throw new InvalidOperationException("The channel must be initialized before it is used.");
        }

        return await this.process.ReadLineAsync();
    }

    public void Reset()
    {
        if ( ( this.process is not null ) && ! this.process.HasExited )
        {
            this.process.Stop();
        }

        this.process = null;
    }

    protected abstract string GetCommandArguments();

    protected virtual void InitializeChannel(bool forceReset = false)
    {
        if ( forceReset )
        {
            this.Reset();
        }

        if ( this.process is null || this.process.HasExited )
        {
            if ( this.commandPath is null )
            {
                throw new InvalidOperationException("The command path has not been set; it must be set before a channel can be initialized");
            }

            this.process = new Process(this.commandPath, GetCommandArguments());
        }

        this.process.Start();
    }

    Process? process;
    string? commandPath;
}
