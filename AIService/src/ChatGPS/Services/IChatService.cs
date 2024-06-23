//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//


using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public interface IChatService
{
    public ChatHistory CreateChat(string prompt);
    public Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history);
    public Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string, object?>? parameters);
}
