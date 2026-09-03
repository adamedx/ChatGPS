//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//

using System.Net;
using System.Net.Http.Headers;

namespace Modulus.ChatGPS.Services;

internal sealed class AnthropicRetryHandler : DelegatingHandler
{
    private const int MaxRetries = 3;
    private static readonly TimeSpan DefaultRetryDelay = TimeSpan.FromSeconds(1);

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var content = request.Content is not null ?
            await request.Content.ReadAsByteArrayAsync(cancellationToken).ConfigureAwait(false) :
            null;

        for ( int attempt = 0; ; attempt++ )
        {
            using var retryRequest = CreateRequest(request, content);
            var response = await base.SendAsync(retryRequest, cancellationToken).ConfigureAwait(false);

            if ( response.StatusCode != HttpStatusCode.TooManyRequests || attempt >= MaxRetries )
            {
                return response;
            }

            var retryDelay = GetRetryDelay(response);
            response.Dispose();

            await Task.Delay(retryDelay, cancellationToken).ConfigureAwait(false);
        }
    }

    private static HttpRequestMessage CreateRequest(HttpRequestMessage source, byte[]? content)
    {
        var request = new HttpRequestMessage(source.Method, source.RequestUri)
        {
            Version = source.Version,
            VersionPolicy = source.VersionPolicy
        };

        foreach ( var header in source.Headers )
        {
            request.Headers.TryAddWithoutValidation(header.Key, header.Value);
        }

        if ( content is not null )
        {
            request.Content = new ByteArrayContent(content);

            foreach ( var header in source.Content!.Headers )
            {
                request.Content.Headers.TryAddWithoutValidation(header.Key, header.Value);
            }
        }

        return request;
    }

    private static TimeSpan GetRetryDelay(HttpResponseMessage response)
    {
        RetryConditionHeaderValue? retryAfter = response.Headers.RetryAfter;

        if ( retryAfter?.Delta is not null && retryAfter.Delta.Value >= TimeSpan.Zero )
        {
            return retryAfter.Delta.Value;
        }

        if ( retryAfter?.Date is not null )
        {
            var delay = retryAfter.Date.Value - DateTimeOffset.UtcNow;

            if ( delay >= TimeSpan.Zero )
            {
                return delay;
            }
        }

        return DefaultRetryDelay;
    }
}
