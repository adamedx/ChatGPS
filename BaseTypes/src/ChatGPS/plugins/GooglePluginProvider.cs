//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
//

namespace Modulus.ChatGPS.Plugins;

public sealed class GooglePluginProvider : PluginProvider
{
    public GooglePluginProvider() : base("Google", "Enables access to search the web using Google.")
    {
        AddPluginParameter("apiKey", "Key credential for accessing the Google Custom Search API.", true, true);
        AddPluginParameter("apiUri", "URI for the API if there is no default URI or if a specific URI is needed.");
        AddPluginParameter("searchEngineId", "Id for the Google search engine instance.", true);
    }

    public override object GetNativeInstance(Dictionary<string, PluginParameterValue>? parameters = null, IShellContext? context = null)
    {
        if ( parameters is null )
        {
            throw new ArgumentException("The Google plugin requires an API key and search engine ID.");
        }

        if ( this.nativeInstance is null )
        {
            var apiKey = (string?) GetPluginParameter("apiKey", parameters);
            var searchEngineId = (string?) GetPluginParameter("searchEngineId", parameters);
            var apiUri = (string?) GetPluginParameter("apiUri", parameters);

            this.nativeInstance = new GoogleNativePlugin(apiKey ?? string.Empty, searchEngineId ?? string.Empty, apiUri);
        }

        return this.nativeInstance;
    }

    private object? nativeInstance;
}
