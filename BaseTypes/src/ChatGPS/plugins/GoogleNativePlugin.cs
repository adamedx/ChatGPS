//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//

using System.ComponentModel;
using System.Text.Json;

namespace Modulus.ChatGPS.Plugins;

[Description("Enables access to search the web using Google.")]
public sealed class GoogleNativePlugin
{
    public GoogleNativePlugin(string apiKey, string searchEngineId, string? apiUri = null)
    {
        if ( string.IsNullOrWhiteSpace(apiKey) )
        {
            throw new ArgumentException("The Google API key cannot be empty.", nameof(apiKey));
        }

        if ( string.IsNullOrWhiteSpace(searchEngineId) )
        {
            throw new ArgumentException("The Google search engine ID cannot be empty.", nameof(searchEngineId));
        }

        this.apiKey = apiKey;
        this.searchEngineId = searchEngineId;
        if ( ! string.IsNullOrWhiteSpace(apiUri) )
        {
            var parsedApiUri = new Uri(apiUri, UriKind.Absolute);

            if ( parsedApiUri.Scheme != Uri.UriSchemeHttp && parsedApiUri.Scheme != Uri.UriSchemeHttps )
            {
                throw new ArgumentException("The Google API URI must use HTTP or HTTPS.", nameof(apiUri));
            }

            this.apiUri = parsedApiUri;
        }
    }

    [Description("Perform a web search.")]
    public async Task<string> SearchAsync(
        [Description("Search query")] string query,
        [Description("Number of results")] int count = 10,
        [Description("Number of results to skip")] int offset = 0,
        CancellationToken cancellationToken = default)
    {
        var results = await SearchCoreAsync(query, count, offset, cancellationToken).ConfigureAwait(false);

        if ( results.Count == 0 )
        {
            throw new InvalidOperationException("Failed to get a response from the web search engine.");
        }

        if ( count == 1 )
        {
            return results[0].Snippet ?? string.Empty;
        }

        return JsonSerializer.Serialize(results.Select(result => result.Snippet ?? string.Empty));
    }

    [Description("Perform a web search and return complete results.")]
    public async Task<string> GetSearchResultsAsync(
        [Description("Text to search for")] string query,
        [Description("Number of results")] int count = 1,
        [Description("Number of results to skip")] int offset = 0,
        CancellationToken cancellationToken = default)
    {
        var results = await SearchCoreAsync(query, count, offset, cancellationToken).ConfigureAwait(false);

        if ( results.Count == 0 )
        {
            throw new InvalidOperationException("Failed to get a response from the web search engine.");
        }

        return JsonSerializer.Serialize(results.Select(result => new GoogleWebPage
        {
            Name = result.Title,
            Snippet = result.Snippet,
            Url = result.Link
        }));
    }

    private async Task<List<GoogleSearchResult>> SearchCoreAsync(
        string query,
        int count,
        int offset,
        CancellationToken cancellationToken)
    {
        if ( count is <= 0 or > 10 )
        {
            throw new ArgumentOutOfRangeException(nameof(count), count, "The count must be greater than 0 and less than or equal to 10.");
        }

        if ( offset < 0 )
        {
            throw new ArgumentOutOfRangeException(nameof(offset));
        }

        var requestUri = new UriBuilder(this.apiUri ?? new Uri("https://www.googleapis.com/customsearch/v1"));
        var queryParameters = new Dictionary<string, string>
        {
            ["key"] = this.apiKey,
            ["cx"] = this.searchEngineId,
            ["q"] = query,
            ["num"] = count.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["start"] = (offset + 1).ToString(System.Globalization.CultureInfo.InvariantCulture)
        };

        var requestQuery = string.Join("&", queryParameters.Select(parameter =>
            $"{Uri.EscapeDataString(parameter.Key)}={Uri.EscapeDataString(parameter.Value)}"));
        var existingQuery = requestUri.Query.TrimStart('?');
        requestUri.Query = string.IsNullOrEmpty(existingQuery) ? requestQuery : $"{existingQuery}&{requestQuery}";

        using var response = await httpClient.GetAsync(requestUri.Uri, cancellationToken).ConfigureAwait(false);
        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);

        if ( ! response.IsSuccessStatusCode )
        {
            throw new InvalidOperationException($"Google Custom Search API returned HTTP {(int) response.StatusCode}: {GetGoogleErrorMessage(responseContent)}");
        }

        var searchResponse = JsonSerializer.Deserialize<GoogleSearchResponse>(responseContent, jsonSerializerOptions);

        return searchResponse?.Items ?? new List<GoogleSearchResult>();
    }

    private static readonly HttpClient httpClient = new();
    private static readonly JsonSerializerOptions jsonSerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly string apiKey;
    private readonly string searchEngineId;
    private readonly Uri? apiUri;

    private sealed class GoogleSearchResponse
    {
        public List<GoogleSearchResult>? Items { get; set; }
    }

    private sealed class GoogleSearchResult
    {
        public string? Title { get; set; }
        public string? Snippet { get; set; }
        public string? Link { get; set; }
    }

    private sealed class GoogleWebPage
    {
        public string? Name { get; set; }
        public string? Snippet { get; set; }
        public string? Url { get; set; }
    }

    private static string GetGoogleErrorMessage(string responseContent)
    {
        try
        {
            var errorResponse = JsonSerializer.Deserialize<GoogleErrorResponse>(responseContent, jsonSerializerOptions);

            if ( ! string.IsNullOrWhiteSpace(errorResponse?.Error?.Message) )
            {
                return errorResponse.Error.Message;
            }
        }
        catch (JsonException)
        {
        }

        return "The response did not contain a diagnostic message.";
    }

    private sealed class GoogleErrorResponse
    {
        public GoogleError? Error { get; set; }
    }

    private sealed class GoogleError
    {
        public string? Message { get; set; }
    }
}
