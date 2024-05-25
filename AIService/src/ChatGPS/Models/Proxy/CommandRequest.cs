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

        CommandRequest.typeToCommand = new Dictionary<Type, string>();

        foreach ( var command in CommandRequest.commandToType.Keys )
        {
            var commandType = CommandRequest.commandToType[command];

            if ( commandType is null )
            {
                throw new ArgumentException($"The command {command} could not be mapped to a valid type");
            }

            CommandRequest.typeToCommand.Add(commandType, command);
        }
    }

    public CommandRequest() {}

    public static Type? GetCommandRequestType(string command)
    {
        return CommandRequest.commandToType[command];
    }

    public static string? GetCommandNameFromRequestType(Type requestType)
    {
        return CommandRequest.typeToCommand[requestType];
    }

    private static Dictionary<string, Type?> commandToType;
    private static Dictionary<Type, string> typeToCommand;
}

