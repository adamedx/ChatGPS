//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.IO;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Services;

namespace Modulus.ChatGPS;

public class ChatGPS
{
    public static ChatSession CreateSession(AiOptions options, string? aiProxyHostPath, string prompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, string? chatFunctionPrompt = null, string[]? chatFunctionParameters = null, string? logDirectoryPath = null, string? logLevel = null, IChatService? chatService = null)
    {
        var targetChatService = chatService;

        string? proxyLogPath = null;

        if ( logDirectoryPath is not null )
        {
            var logDirectoryInfo = new DirectoryInfo(logDirectoryPath);

            if ( logDirectoryInfo.Exists )
            {
                proxyLogPath = Path.Join(logDirectoryInfo.FullName, "ChatGPSProxy.log");
            }
        }

        if ( targetChatService == null )
        {
            if ( aiProxyHostPath is not null && aiProxyHostPath.Length > 0 )
            {
                targetChatService = new ProxyService(options, aiProxyHostPath, proxyLogPath, logLevel);
            }
            else
            {
                ServiceBuilder builder = ServiceBuilder.CreateBuilder();

                targetChatService = builder.WithOptions(options).Build();
            }
        }

        string? targetChatFunctionPrompt = string.IsNullOrEmpty(chatFunctionPrompt) ? null : chatFunctionPrompt;

        return new ChatSession(targetChatService, prompt, tokenStrategy, null, targetChatFunctionPrompt, chatFunctionParameters);
    }
}
