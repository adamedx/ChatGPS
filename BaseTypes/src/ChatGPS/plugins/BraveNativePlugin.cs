//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.ComponentModel;
using System.Text.Json;

namespace Modulus.ChatGPS.Plugins;

[Description("Enables access to search the web / Internet using Brave.")]
public sealed class BraveNativePlugin
{
    public BraveNativePlugin(string apiKey, string? apiUri = null)
    {
        if ( string.IsNullOrWhiteSpace(apiKey) )
        {
            throw new ArgumentException("The Brave API key cannot be empty.", nameof(apiKey));
        }

        this.apiKey = apiKey;
        if ( ! string.IsNullOrWhiteSpace(apiUri) )
        {
            var parsedApiUri = new Uri(apiUri, UriKind.Absolute);

            if ( parsedApiUri.Scheme != Uri.UriSchemeHttp && parsedApiUri.Scheme != Uri.UriSchemeHttps )
            {
                throw new ArgumentException("The Brave API URI must use HTTP or HTTPS.", nameof(apiUri));
            }

            this.apiUri = parsedApiUri;
        }
    }

    [Description("Perform a web / internet search.")]
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
            return results[0].Description ?? string.Empty;
        }

        return JsonSerializer.Serialize(results.Select(result => result.Description ?? string.Empty));
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

        return JsonSerializer.Serialize(results.Select(result => new BraveSearchResult
        {
            Name = result.Title,
            Snippet = result.Description,
            Url = result.Url
        }));
    }

    private async Task<List<BraveWebPage>> SearchCoreAsync(
        string query,
        int count,
        int offset,
        CancellationToken cancellationToken)
    {
        if ( count is <= 0 or > 20 )
        {
            throw new ArgumentOutOfRangeException(nameof(count), count, "The count must be greater than 0 and no greater than 20.");
        }

        if ( offset < 0 || offset % 20 != 0 )
        {
            throw new ArgumentOutOfRangeException(nameof(offset), offset, "The offset must be a non-negative multiple of 20.");
        }

        var requestUri = new UriBuilder(this.apiUri ?? new Uri("https://api.search.brave.com/res/v1/web/search"));
        var queryParameters = new Dictionary<string, string>
        {
            ["q"] = query,
            ["count"] = count.ToString(System.Globalization.CultureInfo.InvariantCulture)
        };

        if ( offset > 0 )
        {
            queryParameters["offset"] = offset.ToString(System.Globalization.CultureInfo.InvariantCulture);
        }

        var requestQuery = string.Join("&", queryParameters.Select(parameter =>
            $"{Uri.EscapeDataString(parameter.Key)}={Uri.EscapeDataString(parameter.Value)}"));
        var existingQuery = requestUri.Query.TrimStart('?');
        requestUri.Query = string.IsNullOrEmpty(existingQuery) ? requestQuery : $"{existingQuery}&{requestQuery}";

        using var request = new HttpRequestMessage(HttpMethod.Get, requestUri.Uri);
        request.Headers.Add("X-Subscription-Token", this.apiKey);

        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);

        if ( ! response.IsSuccessStatusCode )
        {
            throw new InvalidOperationException($"Brave Search API returned HTTP {(int) response.StatusCode}: {GetBraveErrorMessage(responseContent)}");
        }

        var searchResponse = JsonSerializer.Deserialize<BraveSearchResponse>(responseContent, jsonSerializerOptions);

        return searchResponse?.Web?.Results ?? new List<BraveWebPage>();
    }

    private static readonly HttpClient httpClient = new();
    private static readonly JsonSerializerOptions jsonSerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly string apiKey;
    private readonly Uri? apiUri;

    private sealed class BraveSearchResponse
    {
        public BraveWebPages? Web { get; set; }
    }

    private sealed class BraveWebPages
    {
        public List<BraveWebPage>? Results { get; set; }
    }

    private sealed class BraveWebPage
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Url { get; set; }
    }

    private sealed class BraveSearchResult
    {
        public string? Name { get; set; }
        public string? Snippet { get; set; }
        public string? Url { get; set; }
    }

    private static string GetBraveErrorMessage(string responseContent)
    {
        try
        {
            var errorResponse = JsonSerializer.Deserialize<BraveErrorResponse>(responseContent, jsonSerializerOptions);

            if ( ! string.IsNullOrWhiteSpace(errorResponse?.Message) )
            {
                return $"{errorResponse.Message} ({errorResponse.Detail})";
            }
        }
        catch (JsonException)
        {
        }

        return "The response did not contain a diagnostic message.";
    }

    private sealed class BraveErrorResponse
    {
        public string? Message { get; set; }
        public string? Detail { get; set; }
    }
}
