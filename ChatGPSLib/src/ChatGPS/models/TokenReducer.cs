//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using Microsoft.SemanticKernel.AI.ChatCompletion;
using Modulus.ChatGPS.Services;

class TokenReducer
{
    public TokenReducer(IChatService chatService, TokenReductionStrategy strategy, object? parameters)
    {
        this.chatService = chatService;
        this.strategy = strategy;

        this.pastLimitTokenSize = new List<double>();
        this.reducedTokenSize = new List<double>();

        this.readOnlyPastLimitTokenSize = new ReadOnlyCollection<double>(this.pastLimitTokenSize);
        this.readOnlyReducedTokenSize = new ReadOnlyCollection<double>(this.reducedTokenSize);

        switch ( strategy )
        {
        case TokenReductionStrategy.None:
            break;
        case TokenReductionStrategy.Truncate:
            this.truncationPercent = ( parameters != null ) ? (double) parameters : 0.5;
            break;
        default:
            throw new NotImplementedException("The specified token reduction strategy is not yet implemented.");
        }
    }

    public ChatHistory? Reduce(ChatHistory chatHistory)
    {
        if ( this.strategy == TokenReductionStrategy.None )
        {
            return null;
        }

        var tokenEstimate = GetTokenCountForSequence(chatHistory);
        var tokenTarget = tokenEstimate * (1 - this.truncationPercent);

        var historySize = chatHistory.Count;
        int lossIndexStart = 4;

        // Ensure that loss starts with an assistant message, with the idea that
        // the last message we received was from the assistant, and that this means
        // every communication started with a user and ended with an assistant, which
        // is not necessarily the case. Another good thing about this approach is that
        // we can replace the last assistant message with a summary from the assistant and
        // then the conversation can continue.
        if ( lossIndexStart < historySize && chatHistory[lossIndexStart].Role == AuthorRole.User )
        {
            lossIndexStart++;
        }

        // We want to retain the last message in the history, so that means the count
        // must always be odd.
        int retainMostRecentCount = this.lastMessagePairCount * 2 + 1;
        int lossIndexEnd = historySize - retainMostRecentCount;

        if ( lossIndexEnd <= lossIndexStart )
        {
            return null;
        }

        var reducedHistory = this.chatService.CreateChat(chatHistory[0].Content);

        double tokenUsage = GetTokenCountForSequence(reducedHistory);
        bool lastSkipped = false;

        for ( int current = 1; current < historySize; current++ )
        {
            if ( ( current < lossIndexStart )
                 || ( tokenUsage < tokenTarget )
                 || ( current >= lossIndexEnd ) )
            {
                // If this is the first message being added back after skipping messages,
                // Let's make sure it is not an assistant, since we said we want the last
                // retained message to be from an assistant
                if ( lastSkipped && chatHistory[current].Role == AuthorRole.Assistant )
                {
                    reducedHistory.AddMessage(chatHistory[current - 1].Role, chatHistory[current - 1].Content, chatHistory[current - 1].AdditionalProperties);
                    tokenUsage += GetTokenCountForMessage(chatHistory[current - 1]);
                }

                reducedHistory.AddMessage(chatHistory[current].Role, chatHistory[current].Content, chatHistory[current].AdditionalProperties);
                tokenUsage += GetTokenCountForMessage(chatHistory[current]);

                lastSkipped = false;
            }
            else
            {
                lastSkipped = true;
            }
        }

        this.pastLimitTokenSize.Add(tokenEstimate);
        this.reducedTokenSize.Add(GetTokenCountForSequence(reducedHistory));

        return reducedHistory;
    }

    private double GetTokenCountForMessage(ChatMessage message)
    {
        var whitespace = new char[] { ' ', '\t', '\r', '\n' };

        return message.Content.Split(whitespace, StringSplitOptions.RemoveEmptyEntries).Length * this.wordToTokenFactor;
    }

    private double GetTokenCountForSequence(ChatHistory history, int start = 0, int end = -1)
    {
        double tokenCount = 0;

        int targetEnd = end != -1 ? end : history.Count - 1;

        for ( int current = start; current <= targetEnd; current++ )
        {
            tokenCount += GetTokenCountForMessage(history[current]);
        }

        return tokenCount;
    }

    public ReadOnlyCollection<double> PastLimitTokenSize
    {
        get
        {
            return this.readOnlyPastLimitTokenSize;
        }
    }

    public ReadOnlyCollection<double> ReducedTokenSize
    {
        get
        {
            return this.readOnlyReducedTokenSize;
        }
    }

    private IChatService chatService;
    private TokenReductionStrategy strategy;

    private double truncationPercent;
    private double wordToTokenFactor = 1.2;

    private int lastMessagePairCount = 2;

    private List<double> pastLimitTokenSize;
    private List<double> reducedTokenSize;

    private ReadOnlyCollection<double> readOnlyPastLimitTokenSize;
    private ReadOnlyCollection<double> readOnlyReducedTokenSize;
}
