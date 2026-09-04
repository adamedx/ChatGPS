//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.ComponentModel;
using System.Text.Encodings.Web;

namespace Modulus.ChatGPS.Plugins;

[Description("Computes the search url for popular websites.")]
public sealed class SearchUrlNativePlugin
{
    [Description("Return URL for Amazon search query.")]
    public string AmazonSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.amazon.com/s?k={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing search query.")]
    public string BingSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing Images search query.")]
    public string BingImagesSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/images/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing Maps search query.")]
    public string BingMapsSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/maps?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing Shopping search query.")]
    public string BingShoppingSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/shop?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing News search query.")]
    public string BingNewsSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/news/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Bing Travel search query.")]
    public string BingTravelSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.bing.com/travel/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Brave search query.")]
    public string BraveSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://search.brave.com/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Brave Images search query.")]
    public string BraveImagesSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://search.brave.com/images?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Brave News search query.")]
    public string BraveNewsSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://search.brave.com/news?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Brave Goggles search query.")]
    public string BraveGogglesSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://search.brave.com/goggles?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Brave Videos search query.")]
    public string BraveVideosSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://search.brave.com/videos?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for GitHub search query.")]
    public string GitHubSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://github.com/search?q={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for LinkedIn search query.")]
    public string LinkedInSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://www.linkedin.com/search/results/index/?keywords={UrlEncoder.Default.Encode(query)}";
    }

    [Description("Return URL for Wikipedia search query.")]
    public string WikipediaSearchUrl([Description("Text to search for")] string query)
    {
        return $"https://wikipedia.org/w/index.php?search={UrlEncoder.Default.Encode(query)}";
    }
}
