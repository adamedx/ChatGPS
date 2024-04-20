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
    public IChatCompletionService GetChatCompletion(); // Replace with IChatCompletionService.GetChatMessageContentsAsync ?
    public KernelFunction CreateFunction(string definitionPrompt); // May need a name for the function, should return the name
    public Kernel GetKernel(); // InvokeFunction by name
}
