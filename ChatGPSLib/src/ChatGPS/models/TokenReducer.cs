//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Models;

using System.Collections.ObjectModel;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Modulus.ChatGPS.Services;

class TokenReducer
{
    public TokenReducer(ConversationBuilder conversationBuilder, TokenReductionStrategy strategy, object? parameters)
    {
        this.conversationBuilder = conversationBuilder;
        this.strategy = strategy;

        this.pastLimitTokenSize = new List<double>();
        this.reducedTokenSize = new List<double>();

        this.readOnlyPastLimitTokenSize = new ReadOnlyCollection<double>(this.pastLimitTokenSize);
        this.readOnlyReducedTokenSize = new ReadOnlyCollection<double>(this.reducedTokenSize);

        switch ( strategy )
        {
        case TokenReductionStrategy.None:
            break;
        case TokenReductionStrategy.Summarize:
            this.truncationPercent = ( parameters != null ) ? (double) parameters : 0.8;
            break;
        case TokenReductionStrategy.Truncate:
            this.truncationPercent = ( parameters != null ) ? (double) parameters : 0.5;
            break;
        default:
            throw new NotImplementedException("The specified token reduction strategy is not yet implemented.");
        }
    }

    public ChatHistory? Reduce(ChatHistory chatHistory, AuthorRole triggeringRole)
    {
        if ( this.strategy == TokenReductionStrategy.None )
        {
            return null;
        }

        ValidateHistory(chatHistory, triggeringRole);

        var historySize = chatHistory.Count;
        int lossIndexStart = this.startMessageIndex + retainBeginningMessagePairs * 2 - 1;

        int retainMostRecentCount = this.lastMessagePairCount * 2 + 1;
        int lossIndexEnd = historySize - retainMostRecentCount;

        if ( lossIndexEnd <= lossIndexStart )
        {
            return null;
        }

        var content = chatHistory[0].Content;

        if ( content is null )
        {
            return null;
        }

        var reducedHistory = this.conversationBuilder.CreateConversationHistory(content);

        var tokenEstimate = GetTokenCountForSequence(chatHistory);
        var tokenTarget = tokenEstimate * (1 - this.truncationPercent);

        double lastRetainedTokenUsage = GetTokenCountForSequence(chatHistory, lossIndexEnd);
        double tokenUsage = GetTokenCountForSequence(reducedHistory) + lastRetainedTokenUsage;

        for ( int current = 1; current < historySize; current+= 2 )
        {
            if ( ( current < lossIndexStart )
                 || ( tokenUsage < tokenTarget )
                 || ( current >= lossIndexEnd ) )
            {
                var pairSize = current != historySize - 1 ? 2 : 1;

                for ( int pairIndex = 0; pairIndex < pairSize; pairIndex++ )
                {
                    if ( ( current == lossIndexEnd ) &&
                         ( pairIndex == 0 ) &&
                         ( this.strategy == TokenReductionStrategy.Summarize ) )
                    {
                        AddSummaryToConversation(reducedHistory, chatHistory, lossIndexStart);
                    }
                    else if ( chatHistory[current + pairIndex].Content == null )
                    {
                        var sourceMessage = chatHistory[current + pairIndex];
                        var sourceMessageContent = sourceMessage.Content;

                        if ( sourceMessageContent is null )
                        {
                            throw new ArgumentException("Encountered a message with null content");
                        }

                        this.conversationBuilder.AddMessageToConversation(reducedHistory, sourceMessage.Role, sourceMessageContent, sourceMessage.Metadata);
                        tokenUsage += GetTokenCountForMessage(reducedHistory[reducedHistory.Count - 1]);
                    }
                }
            }
        }

        this.pastLimitTokenSize.Add(tokenEstimate);
        this.reducedTokenSize.Add(GetTokenCountForSequence(reducedHistory));

        ValidateHistory(reducedHistory, triggeringRole);

        return reducedHistory;
    }

    private void ValidateHistory(ChatHistory history, AuthorRole reductionTriggeringRole )
    {
        if ( history.Count < 1 )
        {
            throw new ArgumentException("History has no message -- it must have at least one message");
        }

        if ( history[0].Content == null )
        {
            throw new ArgumentException("The first history message is null");
        }

        if ( history[0].Role != AuthorRole.System )
        {
            throw new ArgumentException(String.Format("First message in history does not have the valid System role and instead has invalid role {0}", history[0].Role));
        }

        var triggeringMessage = history[history.Count -1];

        if ( triggeringMessage.Role != reductionTriggeringRole )
        {
            throw new ArgumentException(String.Format("The last message that triggered token reduction should have been {0} but was {1} instead", reductionTriggeringRole, triggeringMessage.Role));
        }

        var expectedOffset = triggeringMessage.Role == AuthorRole.Assistant ? 1 : 0;

        if ( history.Count > 1 && ( history.Count % 2 != expectedOffset ) )
        {
            throw new ArgumentException(String.Format("History count had an unexpected offset given the reduction triggering message role of {0}", triggeringMessage.Role));
        }
    }

    private void AddSummaryToConversation(ChatHistory targetHistory, ChatHistory sourceHistory, int summaryEnd)
    {
        var lastMessage = sourceHistory[summaryEnd];

        if ( lastMessage.Role != AuthorRole.Assistant )
        {
            throw new ArgumentException("Message summary cannot be generated for this history because the last response is not from an assistant");
        }

        this.conversationBuilder.AddMessageToConversation(targetHistory, AuthorRole.User, "Please summarize our conversation up to this point, and start the summary by saying 'Also, just to remind us both of our conversation in case we forgot anything, here is a summary what we have been talking about:'.");

        var summaryTask = this.conversationBuilder.SendMessageAsync(targetHistory);

        var summary = summaryTask.Result;

        var summaryWithOriginalResponse = summary + "\n\n" + lastMessage.Content;

        this.conversationBuilder.UpdateHistoryWithResponse(targetHistory, summaryWithOriginalResponse);
    }

    private double GetTokenCountForMessage(ChatMessageContent message)
    {
        if ( message.Content == null )
        {
            throw new ArgumentException("Message content may not be null");
        }

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

    private ConversationBuilder conversationBuilder;
    private TokenReductionStrategy strategy;

    private double truncationPercent;
    private double wordToTokenFactor = 1.2;

    private int lastMessagePairCount = 2;
    private int startMessageIndex = 1;
    private int retainBeginningMessagePairs = 2;

    private List<double> pastLimitTokenSize;
    private List<double> reducedTokenSize;

    private ReadOnlyCollection<double> readOnlyPastLimitTokenSize;
    private ReadOnlyCollection<double> readOnlyReducedTokenSize;
}
