//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;


using Microsoft.SemanticKernel.AI.ChatCompletion;
using Modulus.ChatGPS.Services;

class TokenReducer
{
    public TokenReducer(IChatService chatService, TokenReductionStrategy strategy, object? parameters)
    {
        this.chatService = chatService;
        this.strategy = strategy;

        switch ( strategy )
        {
        case TokenReductionStrategy.None:
            break;
        case TokenReductionStrategy.Truncate:
            this.truncationPercent = ( parameters != null ) ? (double) parameters : -1;
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

        var historySize = chatHistory.Count;
        int lossIndexStart = 5;

        if ( historySize > 1 && chatHistory[1].Role == AuthorRole.User )
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

        for ( int current = 1; current <= lossIndexEnd; current++ )
        {
            if ( current < lossIndexStart || current < lossIndexEnd )
            {
                reducedHistory.AddMessage(chatHistory[current].Role, chatHistory[current].Content);
            }
        }

        return reducedHistory;
    }

    private IChatService chatService;
    private TokenReductionStrategy strategy;
    private double truncationPercent;
}
