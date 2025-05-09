#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

class PowerShellKernelPluginBuilder  {
    [string] $PluginName = $null
    [string] $Description = $null
    [bool] $BuildComplete = $false
    [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]] $Scripts = $null

    static [string[]] $GenerationFiles = $null

    static PowerShellKernelPluginBuilder()
    {
        [PowerShellKernelPluginBuilder]::GenerationFiles = @(
            "$psscriptroot/GeneratePlugin.ps1"
        )
    }

    PowerShellKernelPluginBuilder([string] $pluginName, [string] $description, [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]] $scripts = $null) {
        $this.PluginName = $pluginName
        $this.Description = $description
        $this.scripts = if ( $Scripts ) {
            $Scripts
        } else {
            [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]]::new()
        }
    }

    PowerShellKernelPluginBuilder() {
        $this.scripts = [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellScriptBlock]]::new()
    }

    [void] AddMethod([string] $methodName, [ScriptBlock] $scriptBlock, [string] $description, [string] $OutputType = 'System.String', [string] $outputDescription = $null) {
        $parameterInfo = $this.GetParameterInfo($scriptBlock)

        $newMethod = [Modulus.ChatGPS.Plugins.PowerShellScriptBlock]::new($methodName, $scriptBlock, $parameterInfo, $description, $OutputType, $outputDescription)

        $this.Scripts.Add($methodName, $newMethod)
    }

    [Modulus.ChatGPS.Plugins.PowerShellNativePluginBase] ToKernelPlugin() {
        if ( $this.Buildcomplete ) {
            throw [InvalidOperationException]::new("The object has already been built")
        }

        $definition = GetClassDefinition $this.PluginName $this.Description $this.Scripts

        $creationBlock = [ScriptBlock]::Create(
            "param(`$scripts) $definition; [$($this.PluginName)]::new(`$scripts)" )

        $kernelPlugin = $creationBlock.InvokeReturnAsIs($this.Scripts)

        $this.BuildComplete = $true

        return $kernelPlugin
    }

    hidden [System.Collections.Generic.Dictionary[string,string]] GetParameterInfo([ScriptBlock] $scriptBlock) {
        $result = [System.Collections.Generic.Dictionary[string,string]]::new()

        if ( $scriptBlock.ast.ParamBlock -and ( $scriptBlock.ast.ParamBlock | get-member parameters -erroraction ignore ) ) {
            foreach ( $parameter in $scriptBlock.ast.ParamBlock.parameters ) {
                $result.Add($parameter.name, $parameter.StaticType)
            }
        }

        return $result
    }

}
