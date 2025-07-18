//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
            { "sendchat", typeof(SendChatRequest) },
            { "invokefunction", typeof(InvokeFunctionRequest) }
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


