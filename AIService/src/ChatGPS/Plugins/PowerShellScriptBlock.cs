//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Language;

using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Plugins;

public class PowerShellScriptBlock
{
    public PowerShellScriptBlock(string name, string scriptBlock, Dictionary<string,string> parameterTable, string description, string? outputType, string? outputDescription = null)
    {
        this.Name = name;
        this.Description = description;
        this.OutputType = outputType;
        this.OutputDescription = outputDescription ?? "This function returns no output; it only produces side effects";
        this.ScriptBlock = scriptBlock;
    }

    public PowerShellScriptBlock() {}

    public ReadOnlyDictionary<string,string> GetParameterTable()
    {
        var parameterTable = new Dictionary<string,string>();

        var scriptBlock = System.Management.Automation.ScriptBlock.Create(this.ScriptBlock);

        ScriptBlockAst scriptAst = (ScriptBlockAst) scriptBlock.Ast;

        var scriptParameters = scriptAst?.ParamBlock?.Parameters;

        if ( scriptParameters is not null )
        {
            foreach ( var parameter in scriptParameters )
            {
                if ( parameter.StaticType is not null && parameter.StaticType.FullName is not null)
                {
                    parameterTable.Add(parameter.Name.ToString(), parameter.StaticType.FullName);
                }
            }
        }

        return new ReadOnlyDictionary<string,string>(parameterTable);
    }

    public string? Name { get; set; }
    public string? Description { get;  set; }
    public string? OutputType { get; set; }
    public string? OutputDescription { get; set; }
    public string? ScriptBlock { get; set; }
}
