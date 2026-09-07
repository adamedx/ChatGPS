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

namespace Modulus.ChatGPS.Plugins;

[Description("Enables the local computer to access local and remote resources via http protocol requests.")]
public sealed class HttpNativePlugin
{
    public HttpNativePlugin()
        : this(allowedDomains: null, disallowedDomains: null, allowRedirect: false)
    { }

    public HttpNativePlugin(string[]? allowedDomains, string[]? disallowedDomains, bool allowRedirect = false)
    {
        if ( (allowedDomains is { Length: > 0 } ) && (disallowedDomains is { Length: > 0 } ) )
        {
            throw new ArgumentException("The allowedDomains and disallowedDomains parameters may not both be specified.");
        }

        this.allowedDomains = allowedDomains ?? Array.Empty<string>();
        this.disallowedDomains = disallowedDomains ?? Array.Empty<string>();
        this.allowRedirect = allowRedirect;

        this.httpClient = new HttpClient(new HttpClientHandler { AllowAutoRedirect = allowRedirect });
    }

    public static string[] ParseDomains(string? domains)
    {
        if ( string.IsNullOrWhiteSpace(domains) )
        {
            return Array.Empty<string>();
        }

        var result = domains.Split([','], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                            .Select(d => d.ToLowerInvariant())
                            .Distinct()
                            .ToArray();

        foreach ( var domain in result )
        {
            if ( ! ( Uri.CheckHostName(domain) is UriHostNameType.Dns or UriHostNameType.IPv4 ) )
            {
                throw new ArgumentException($"The domain name '{domain}' is not a valid domain name.");
            }
        }

        return result;
    }

    [Description("Makes a GET request to a uri")]
    public Task<string> GetAsync(
        [Description("The URI of the request")] string uri,
        CancellationToken cancellationToken = default)
    {
        return this.SendRequestAsync(uri, HttpMethod.Get, requestContent: null, cancellationToken);
    }

    [Description("Makes a POST request to a uri")]
    public Task<string> PostAsync(
        [Description("The URI of the request")] string uri,
        [Description("The body of the request")] string body,
        CancellationToken cancellationToken = default)
    {
        return this.SendRequestAsync(uri, HttpMethod.Post, new StringContent(body), cancellationToken);
    }

    [Description("Makes a PUT request to a uri")]
    public Task<string> PutAsync(
        [Description("The URI of the request")] string uri,
        [Description("The body of the request")] string body,
        CancellationToken cancellationToken = default)
    {
        return this.SendRequestAsync(uri, HttpMethod.Put, new StringContent(body), cancellationToken);
    }

    [Description("Makes a DELETE request to a uri")]
    public Task<string> DeleteAsync(
        [Description("The URI of the request")] string uri,
        CancellationToken cancellationToken = default)
    {
        return this.SendRequestAsync(uri, HttpMethod.Delete, requestContent: null, cancellationToken);
    }

    private async Task<string> SendRequestAsync(
        string uri,
        HttpMethod method,
        HttpContent? requestContent,
        CancellationToken cancellationToken)
    {
        var requestUri = new Uri(uri);

        if ( ! this.IsDomainAllowed(requestUri.Host) )
        {
            throw new InvalidOperationException($"The domain '{requestUri.Host}' is not allowed for HTTP requests.");
        }

        using var request = new HttpRequestMessage(method, requestUri) { Content = requestContent };

        using var response = await this.httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);

        if ( ! response.IsSuccessStatusCode )
        {
            var responseText = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            throw new InvalidOperationException($"The HTTP {method.Method} request to {requestUri} returned {(int) response.StatusCode}: {responseText}");
        }

        return await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
    }

    private bool IsDomainAllowed(string host)
    {
        var hostname = host.ToLowerInvariant();

        if ( this.allowedDomains.Length > 0 )
        {
            return this.allowedDomains.Any(d => hostname == d || hostname.EndsWith("." + d, StringComparison.Ordinal));
        }

        if ( this.disallowedDomains.Length > 0 )
        {
            return ! this.disallowedDomains.Any(d => hostname == d || hostname.EndsWith("." + d, StringComparison.Ordinal));
        }

        return true;
    }

    private readonly string[] allowedDomains;
    private readonly string[] disallowedDomains;
    private readonly bool allowRedirect;
    private readonly HttpClient httpClient;
}
