//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

namespace Modulus.ChatGPS.Plugins;

public class PowerShellFunctionInfo
{
    PowerShellFunctionInfo(
        string name,
        string description,
        string outputDescription)
    {
        this.Name = name;
        this.Description = description;
        this.OutputDescription = outputDescription;
    }

    public string Name { get; private set; }
    public string Description { get; private set; }
    public string OutputDescription { get; private set; }
}

