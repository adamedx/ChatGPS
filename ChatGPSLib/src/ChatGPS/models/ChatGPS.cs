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
            targetChatService =
                aiProxyHostPath is not null ?
                new ProxyService(ServiceBuilder.ServiceId.AzureOpenAi, options, aiProxyHostPath, proxyLogPath, logLevel) :
                new OpenAIChatService(options);
        }

        string? targetChatFunctionPrompt = string.IsNullOrEmpty(chatFunctionPrompt) ? null : chatFunctionPrompt;

        return new ChatSession(targetChatService, prompt, tokenStrategy, null, targetChatFunctionPrompt, chatFunctionParameters);
    }
}
