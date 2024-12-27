//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using System.Text.Json;
using System.Text.Json.Nodes;
using Modulus.ChatGPS.Services;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

public class ChatMessage
{
    public ChatMessage(ChatMessageContent sourceMessage)
    {
        this.sourceMessage = sourceMessage;
    }

    public AuthorRole Role
    {
        get
        {
            return this.sourceMessage.Role;
        }
    }

    public string? Content
    {
        get
        {
            return this.sourceMessage.Content;
        }
    }

    public System.Collections.Generic.IReadOnlyDictionary<string,object?>? Metadata
    {
        get
        {
            return this.sourceMessage.Metadata;
        }
    }

    internal ChatMessageContent SourceChatMessageContent
    {
        get
        {
            return sourceMessage;
        }
    }

    private ChatMessageContent sourceMessage;
}
