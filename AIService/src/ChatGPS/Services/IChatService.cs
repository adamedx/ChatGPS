//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//


using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Plugins;

namespace Modulus.ChatGPS.Services;

public interface IChatService
{
    public ChatHistory CreateChat(string prompt);
    public Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history, bool? allowAgentAccess = null);
    public Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string, object?>? parameters);
    public void AddPlugin(string pluginName, object[]? parameters);
    public void RemovePlugin(string pluginName);
    public IEnumerable<PluginInfo> Plugins { get; }
    public AiOptions ServiceOptions { get; }
}
