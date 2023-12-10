//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.AI.ChatCompletion;

public interface IChatService
{
    public ChatHistory CreateChat(string prompt);
    public IChatCompletion GetChatCompletion();
    public ISKFunction CreateFunction(string definitionPrompt);
}
