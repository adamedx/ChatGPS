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

public interface IChatService : IPluginTable
{
    public void Initialize();
    public ChatHistory CreateChat(string prompt);
    public Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history, bool? allowAgentAccess = null);
    public Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string, object?>? parameters, bool? allowFunctionCall);
    public AiOptions ServiceOptions { get; }
}
