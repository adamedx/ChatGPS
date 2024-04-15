//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

public interface IChatService
{
    public ChatHistory CreateChat(string prompt);
    public IChatCompletionService GetChatCompletion();
    public KernelFunction CreateFunction(string definitionPrompt);
    public Kernel GetKernel();
}
