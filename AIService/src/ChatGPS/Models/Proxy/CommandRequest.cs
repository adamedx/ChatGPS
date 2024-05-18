//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models.Proxy;

public class CommandRequest
{
    static CommandRequest()
    {
        CommandRequest.commandToType = new Dictionary<string, Type?>()
        {
            { "createconnection", typeof(CreateConnectionRequest) },
            { "exit", typeof(ExitRequest) },
            { "sendchat", typeof(SendChatRequest) }
        };

        foreach ( var command in CommandRequest.commandToType.Keys )
        {
            if ( CommandRequest.commandToType[command] is null )
            {
                throw new ArgumentException($"The command {command} could not be mapped to a valid type");
            }
        }
    }

    public CommandRequest() {}

    public static Type? GetCommandRequestType(string command)
    {
        return CommandRequest.commandToType[command];
    }

    private static Dictionary<string, Type?> commandToType;
}

