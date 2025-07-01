//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text.Json;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellPluginProvider : PluginProvider
{
    public PowerShellPluginProvider(string name, object kernelPlugin, string? generationScriptPath) : base(name)
    {
        this.generationScriptPath = generationScriptPath;
        this.kernelPlugin = kernelPlugin;
    }

    public PowerShellPluginProvider(string name, string description, Dictionary<string,PowerShellScriptBlock>? scripts, string? generationScriptPath) : base(name, description)
    {
        this.PluginDescription = description;
        this.Scripts = scripts;
        this.generationScriptPath = generationScriptPath;
    }

    // TODO: This constructor must stay for now -- there is a runtime (not compile time) requirement for its existence at the moment.
    public PowerShellPluginProvider(string name) : base(name) { }

    public PowerShellPluginProvider(string name, string? description) : base(name, description) { }

    public ReadOnlyDictionary<string,PowerShellScriptBlock>? GetScripts()
    {
        return this.Scripts is not null ? new ReadOnlyDictionary<string,PowerShellScriptBlock>(this.Scripts) : null;
    }

    internal override void InitializeInstanceFromData(string[] jsonData)
    {
        if ( jsonData.Length < 3 )
        {
            throw new ArgumentException("Invalid data was used to initialize the data");
        }

        this.PluginDescription = JsonSerializer.Deserialize<string?>(jsonData[1]);
        this.Scripts = (Dictionary<string,PowerShellScriptBlock>?) JsonSerializer.Deserialize<Dictionary<string,PowerShellScriptBlock>?>(jsonData[2]);
        this.generationScriptPath = (string?) JsonSerializer.Deserialize<string?>(jsonData[3]);
    }

    internal override string[]? GetProviderDataJson()
    {
        var nameJson = JsonSerializer.Serialize(this.Name, this.Name.GetType());
        var descriptionJson = this.PluginDescription is not null ? JsonSerializer.Serialize(this.PluginDescription, this.PluginDescription.GetType()) : "";
        var scriptsJson = this.Scripts is not null ? JsonSerializer.Serialize(this.Scripts, this.Scripts.GetType()) : "";
        var generationScriptJson = this.generationScriptPath is not null ? JsonSerializer.Serialize(this.generationScriptPath, this.generationScriptPath.GetType()) : "";

        var argumentJson = new string[]
        {
            nameJson,
            descriptionJson,
            scriptsJson,
            generationScriptJson
        };

        return argumentJson;
    }

    internal override object GetNativeInstance(Dictionary<string,PluginParameterValue>? parameters = null)
    {
        if ( this.kernelPlugin is null )
        {
            this.kernelPlugin = GenerateKernelPluginFromPowerShellScript();
        }

        return this.kernelPlugin;
    }

    Dictionary<string,PowerShellScriptBlock>? Scripts { get; set; }

    string? PluginDescription { get; set; }

    private object GenerateKernelPluginFromPowerShellScript()
    {
        if ( this.generationScriptPath is null )
        {
            throw new InvalidOperationException("A plugin type may not be generated without a generation script");
        }

        object? kernelPlugin = null;

        var targetDescription = this.PluginDescription ?? "";

        if ( Runspace.DefaultRunspace is null )
        {
            var initialSessionState = InitialSessionState.CreateDefault();
            initialSessionState.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.RemoteSigned;

            Runspace.DefaultRunspace = RunspaceFactory.CreateRunspace(initialSessionState);
            Runspace.DefaultRunspace.Open();
        }

        var creationBlock = ScriptBlock.Create($"param($Name, $Description, $Scripts) & {this.generationScriptPath} -Name $Name -Description $Description -Scripts $Scripts");

        object?[] parameters = new object?[]
        {
            this.Name,
                targetDescription,
                this.Scripts,
                this.generationScriptPath
                };

        var result = (PSObject) creationBlock.InvokeReturnAsIs(parameters);

        if ( result is not null )
        {
            kernelPlugin = ((Dictionary<string,object>) result.BaseObject)["result"];
        }

        if ( kernelPlugin is null )
        {
            throw new InvalidOperationException("A plugin could not be generated from the supplied code.");
        }

        return kernelPlugin;
    }

    object? kernelPlugin;

    string? generationScriptPath;
}
