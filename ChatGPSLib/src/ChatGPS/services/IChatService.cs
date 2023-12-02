//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Services;

using Microsoft.SemanticKernel.AI.ChatCompletion;

public interface IChatService
{
     public ChatHistory CreateChat(string prompt);
}
