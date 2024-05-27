//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.AIProxy;

using System.Diagnostics;

internal class Listener
{
    internal Listener(Func<string, (bool finished, string? content)> responder)
    {
        this.responder = responder;
        this.inputStream = System.Console.OpenStandardInput(1);
        this.reader = new StreamReader(this.inputStream);
        this.finishedEvent = new ManualResetEvent(false);
    }

    internal void Start(CancellationTokenSource cancellationTokenSource)
    {
        Logger.Log("Attempting to start listener.");

        if ( this.readThread is not null )
        {
            throw new InvalidOperationException("This listener has already been started");
        }

        this.cancellationTokenSource = cancellationTokenSource;

        this.readThread = new Thread(() => Listen());

        this.readThread.Start();

        Logger.Log("Successfully started listener");
    }

    internal void Stop()
    {
        Logger.Log("Attempting to stop listener.");

        if ( this.cancellationTokenSource is null )
        {
            throw new InvalidOperationException("Cannot start stop because there is no cancellation token source associated with this listener");
        }

        Logger.FlushLog();

        this.cancellationTokenSource.Cancel();

        if ( this.readThread is not null )
        {
            this.finishedEvent.Set();
        }
        else
        {
            throw new InvalidOperationException("The listener cannot be stopped because it has not been correctly initialized");
        }

        Logger.Log("Successfully signaled listener to stop.");

        Logger.Log("Waiting for up to 30s for listener thread to exit.");

        this.readThread.Join(30000);

        var isStopped = this.readThread.ThreadState == System.Threading.ThreadState.Stopped;

        Logger.Log(string.Format("Finished waiting for listener thread to exit, wait for thread to stop was {0}.", isStopped ? "successful" : "unsuccessful"));

        Logger.Log("Finished attempt to stop the listener.");
    }

    internal bool Wait(int timeout)
    {
        Logger.Log($"Started wait for {timeout} milliseconds for listener to finish");

        bool finishedWaiting = false;
        bool exitRequested = false;

        while ( ! finishedWaiting )
        {
            this.waitAgain = false;
            exitRequested = this.finishedEvent.WaitOne(timeout);

            Logger.Log($"Listener event exited with:{exitRequested}, wait again set to {this.waitAgain}");

            // If we haven't been told we're finished but we've been instructed to wait again,
            // then do so
            if ( exitRequested )
            {
                if ( this.waitAgain )
                {
                    this.waitAgain = false;
                    this.finishedEvent.Reset();
                    Logger.Log("Finish waiting event was signaled, but wait again flag was set indicating the timeout has been reset to start again");
                }
                else
                {
                    finishedWaiting = true;
                }
            }
            else
            {
                finishedWaiting = true;
            }
        }

        Logger.Log($"Completed wait for listener -- finished:{exitRequested}");

        return exitRequested;
    }

    private void Listen()
    {
        Logger.Log("Listening for input");

        if ( this.cancellationTokenSource is null )
        {
            throw new InvalidOperationException("Cannot start listening because there is no cancellation token source associated with this listener");
        }

        if ( this.inputStream is null )
        {
            throw new InvalidOperationException("There is no input stream for the listener to read from");
        }

        var cancellationToken = this.cancellationTokenSource.Token;

        cancellationToken.Register(CancelRead);

        bool finished = false;

        while ( ! finished )
        {
            string? request = null;

            try
            {
                var task = this.reader.ReadLineAsync(cancellationToken);
                var tasks = new Task[] { task.AsTask() };

                Task.WaitAll(tasks, cancellationToken);

                request = task.Result;

                finished = request is null;

                if ( ! finished )
                {
                    // Reset the idle timer for waiting for input -- now that
                    // we've received some input, we can wait for additional time
                    this.waitAgain = true;
                    this.finishedEvent.Set();

                    var response = responder.Invoke(request ?? "");

                    finished = response.finished;

                    if ( finished )
                    {
                        Logger.Log("The input stream contained an instruction to stop listening, will stop listening");
                    }
                }
                else
                {
                    Logger.Log("The input stream has no more input, will stop listening.");
                }
            }
            catch ( TaskCanceledException )
            {
                Logger.Log("The listener received a request to cancel reading input after queuing a task, will stop listening");
                finished = true;
            }
            catch ( OperationCanceledException )
            {
                Logger.Log("The listener received a request to cancel reading input before queuing a task, will stop listening");
                finished = true;
            }

            if ( this.finishedEvent.WaitOne(0) )
            {
                Logger.Log("The listener received a request to cancel listening, will stop listening");
                finished = true;
            }
        }

        this.finishedEvent.Set();

        Logger.Log("Listening has completed");
    }

    void CancelRead()
    {
        Logger.Log("Received request to cancel reading input");

        this.reader.Close();

        Logger.Log("Closed reader in order to cancel reading input");
    }

    private Func<string, (bool finished, string? content)> responder;
    private Stream? inputStream;
    private Thread? readThread;
    private StreamReader reader;
    private ManualResetEvent finishedEvent;
    private bool waitAgain = false;
    private CancellationTokenSource? cancellationTokenSource;
}

