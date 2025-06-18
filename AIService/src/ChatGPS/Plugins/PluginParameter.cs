//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Plugins;

public class PluginParameter
{
    internal PluginParameter(string name, string description, bool required = false, bool encrypted = false)
    {
        this.Name = name;
        this.Description = description;
        this.Required = required;
        this.Encrypted = encrypted;
    }

    public string Name { get; private set; }
    public string Description { get; private set; }
    public bool Required { get; private set; }
    public bool Encrypted { get; private set; }
}
