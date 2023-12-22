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
        var tokenTarget = tokenEstimate * truncationPercent;

        var historySize = chatHistory.Count;
        int lossIndexStart = 4;

        if ( lossIndexStart < historySize && chatHistory[1].Role == AuthorRole.User )
        {
            lossIndexStart++;
        }

        int retainMostRecentCount = 4;
        int lossIndexEnd = historySize - retainMostRecentCount;

        if ( lossIndexEnd <= lossIndexStart )
        {
            return null;
        }

        var reducedHistory = this.chatService.CreateChat(chatHistory[0].Content);

        double tokenUsage = GetTokenCountForSequence(chatHistory, historySize - retainMostRecentCount, historySize - 1);

        for ( int current = 0; current < historySize; current++ )
        {
            tokenUsage += GetTokenCountForMessage(chatHistory[current]);

            if ( ( current < lossIndexStart )
                 || ( tokenUsage < tokenTarget )
                 || ( current >= lossIndexEnd ) )
            {
                reducedHistory.AddMessage(chatHistory[current].Role, chatHistory[current].Content);
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

    private List<double> pastLimitTokenSize;
    private List<double> reducedTokenSize;

    private ReadOnlyCollection<double> readOnlyPastLimitTokenSize;
    private ReadOnlyCollection<double> readOnlyReducedTokenSize;
}
