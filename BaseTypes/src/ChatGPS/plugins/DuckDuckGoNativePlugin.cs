//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//

using System.ComponentModel;
using System.Text.Json;

namespace Modulus.ChatGPS.Plugins;

[Description("Enables access to DuckDuckGo's Instant Answer API.")]
public sealed class DuckDuckGoNativePlugin
{
    [Description("Look up an instant answer based on a subset of the web / internet, including support for some calculations, checking the status of a flight, word definitions and synonyms, etc. This API provides summaries and related topics, not ranked web search results, and might have an answer if you don't already have a tool that can give ranked web results and just want a web-based answer.")]
    public async Task<string> SearchAsync(
        [Description("The question or topic to look up")] string query,
        CancellationToken cancellationToken = default)
    {
        var response = await this.GetResponseAsync(query, cancellationToken).ConfigureAwait(false);
        var answer = response.AbstractText;

        if ( string.IsNullOrWhiteSpace(answer) )
        {
            answer = response.Answer;
        }

        if ( string.IsNullOrWhiteSpace(answer) && response.RelatedTopics.Count == 0 )
        {
            throw new InvalidOperationException("DuckDuckGo did not return an instant answer or related topics for the query.");
        }

        var result = new DuckDuckGoAnswer
        {
            Answer = answer,
            Url = response.AbstractUrl,
            RelatedTopics = response.RelatedTopics
                .Where(topic => ! string.IsNullOrWhiteSpace(topic.Text))
                .Select(topic => new DuckDuckGoTopic
                {
                    Text = topic.Text,
                    Url = topic.FirstUrl
                })
                .ToList()
        };

        return JsonSerializer.Serialize(result, jsonSerializerOptions);
    }

    [Description("Look up an instant answer from a subset web / internet and related topic links and or perform calculations, look up flight status, provide dictionary definitions and synonyms using DuckDuckGo instant answers. This API does not return ranked web search results, but may have the answers you need.")]
    public async Task<string> GetSearchResultsAsync(
        [Description("The question or topic to look up")] string query,
        CancellationToken cancellationToken = default)
    {
        return await this.SearchAsync(query, cancellationToken).ConfigureAwait(false);
    }

    private async Task<DuckDuckGoResponse> GetResponseAsync(string query, CancellationToken cancellationToken)
    {
        if ( string.IsNullOrWhiteSpace(query) )
        {
            throw new ArgumentException("The DuckDuckGo query cannot be empty.", nameof(query));
        }

        var requestUri = new UriBuilder("https://api.duckduckgo.com/");
        requestUri.Query = $"q={Uri.EscapeDataString(query)}&format=json&no_html=1&skip_disambig=1";

        using var response = await httpClient.GetAsync(requestUri.Uri, cancellationToken).ConfigureAwait(false);
        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);

        if ( ! response.IsSuccessStatusCode )
        {
            throw new InvalidOperationException($"DuckDuckGo Instant Answer API returned HTTP {(int) response.StatusCode}: {responseContent}");
        }

        return JsonSerializer.Deserialize<DuckDuckGoResponse>(responseContent, jsonSerializerOptions)
            ?? throw new InvalidOperationException("DuckDuckGo returned an empty response.");
    }

    private static readonly HttpClient httpClient = new();
    private static readonly JsonSerializerOptions jsonSerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private sealed class DuckDuckGoResponse
    {
        public string? AbstractText { get; set; }
        public string? AbstractUrl { get; set; }
        public string? Answer { get; set; }
        public List<DuckDuckGoRelatedTopic> RelatedTopics { get; set; } = new();
    }

    private sealed class DuckDuckGoRelatedTopic
    {
        public string? Text { get; set; }
        public string? FirstUrl { get; set; }
    }

    private sealed class DuckDuckGoAnswer
    {
        public string? Answer { get; set; }
        public string? Url { get; set; }
        public List<DuckDuckGoTopic> RelatedTopics { get; set; } = new();
    }

    private sealed class DuckDuckGoTopic
    {
        public string? Text { get; set; }
        public string? Url { get; set; }
    }
}
