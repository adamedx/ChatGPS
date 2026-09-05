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

using System.IO;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;
using Modulus.ChatGPS.Services;

namespace Modulus.ChatGPS;

public class ChatGPS
{
    public static ChatSession CreateSession(AiOptions options, string? aiProxyHostPath, string prompt, TokenReductionStrategy tokenStrategy = TokenReductionStrategy.None, string? logDirectoryPath = null, string? logLevel = null, IChatService? chatService = null, int latestContextLimit = -1, object? customContext = null, string? name = null, string? userAgent = null, IShellContext? clientContext = null)
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
                // When constructing the proxy service, give it an idle timeout of 10 minutes for local models
                // because we happen to know they are actually hosted in the proxy, so when the proxy goes away
                // they must be reloaded, which can be expensive. Otherwise, it is assumed that model lifetime
                // for models hosted over http transport has no correlation to the proxy's lifetime as an http client.
                var idleTimeoutMs = ! string.IsNullOrWhiteSpace(options.LocalModelPath) ? 600000 : 60000;

                targetChatService = new ProxyService(options, aiProxyHostPath, clientContext, proxyLogPath, logLevel, idleTimeoutMs: idleTimeoutMs);
            }
            else
            {
                throw new NotSupportedException("Non proxy mode is not supported in this release.");
            }
        }

        return new ChatSession(targetChatService, prompt, tokenStrategy, null, latestContextLimit, customContext, name);
    }
}

