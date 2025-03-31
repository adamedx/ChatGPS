#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#


class PowerShellKernelPluginBuilder  {
    [string] $PluginName = $null
    [string] $Description = $null
    [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $Scripts = $null

    PowerShellKernelPluginBuilder([string] $pluginName, [string] $description, [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $scripts = $null) {
        $this.PluginName = $pluginName
        $this.Description = $description
        $this.scripts = if ( $Scripts ) {
            $Scripts
        } else {
            [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]]::new()
        }
    }

    [void] AddMethod([string] $methodName, [ScriptBlock] $scriptBlock, [string] $description, [string] $outputDescription = $null) {
        $newMethod = [PowerShellScriptBlock]::new($methodName, $scriptBlock, $description, $outputDescription)

        $this.Scripts.Add($methodName, $newMethod)
    }

    [Modulus.ChatGPS.Plugins.PowerShellKernelPlugin] ToKernelPlugin() {
#    [object] ToKernelPlugin() {
     $definition = GetClassDefinition $this.PluginName $this.Description $this.Scripts

        $creationBlock = [ScriptBlock]::Create(
            "param(`$scripts) $definition; [$($this.PluginName)]::new(`$scripts)" )

        return $creationBlock.InvokeReturnAsIs($this.Scripts)
    }
}

function New-ChatPowerShellPlugin {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $Name,

        [parameter(position=1)]
        [string] $Description,

        [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $Scripts = $null
    )

    [PowerShellKernelPluginBuilder]::new($Name, $Description, $Scripts)
}

function Add-ChatPowerShellPluginFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true, mandatory=$true)]
        [PowerShellKernelPluginBuilder] $Plugin,

        [parameter(position=0, mandatory=$true)]
        [string] $FunctionName,

        [parameter(position=1, mandatory=$true)]
        [ScriptBlock] $ScriptBlock,

        [string] $Description,

        [string] $OutputDescription,

        [switch] $NoOutput
    )

    $targetDescription = if ( $Description ) {
        $Description
    } else {
        "This method invokes PowerShell code to perform its function."
    }

    $Plugin.AddMethod($FunctionName, $ScriptBlock, $Description, $OutputDescription)

    if ( ! $NoOutput.IsPresent ) {
        $Plugin
    }
}

function NewPowerShellKernelPlugin {
    param(
        [string] $pluginName,
        [string] $description,
        [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $Scripts
    )

    $classDefinition = GetClassDefinition $pluginName $description $scriptTable

    $classScript = [ScriptBlock]::Create($classDefinition)

    $classScript.Invoke(@()) | out-null
}

function GetClassDefinition(
    [string] $pluginName,
    [string] $description,
    [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $scriptTable

) {
    @'
[System.ComponentModel.Description("This plugin uses PowerShell to obtain information about processes on the system")]
class ProcessInfo : [Modulus.ChatGPS.Plugins.PowerShellKernelPlugin] {

    ProcessInfo() {}
    ProcessInfo([System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.IPowerShellScriptBlock]] $scriptBlocks) : base($scriptBlocks) {}

    [Microsoft.SemanticKernel.KernelFunctionAttribute("get_process_information")]
    [System.ComponentModel.Description("This method returns an object that describes information about an operating system process based on the process id passes as a parameter")]
    [System.Diagnostics.Process] GetProcessInformation([int] $ProcessId) {
        return (Get-Process -PID $ProcessId)
    }

    [Microsoft.SemanticKernel.KernelFunctionAttribute("get_current_process_identifier")]
    [System.ComponentModel.Description("This method returns the operating system process id for the process executing the plugin.")]
    [int] GetCurrentProcessId() {
        return [system.diagnostics.process]::GetCurrentProcess().Id
    }
}
'@
}

function RenderClassDefinition(
    [string] $pluginName,
    [string] $renderedMethods
) {
   $pluginTemplate = @'
class {0} : Modulus.ChatGPS.Plugins.PowerShellKernelPlugin {{

                                                                PowerShellKernelPlugin([Dictionary[string,Modulus.ChatGPS.Plugins.IPowershellScriptBlock] $scriptBlocks) : base($scriptBlocks) {{ }}

{1}

}}
'@

    $pluginTemplate -f $pluginName, $renderedMethods
}

function RenderClassMethods( [System.Collections.Generic.Dictionary[string,IPowerShellScriptBlock]] $methodTable ) {
    $rendered = foreach ( $methodName in $methodTable.Keys ) {
        RenderMethod $null $methodTable[$methodName]
    }

    $rendered -join "`n`n"
}

function RenderMethod(
    [string] $pluginMethodName,
    [PowerShellScriptBlock] $scriptBlock

) {
    $targetOutputDescription = if ( $scriptBlock.outputDescription ) {
        $scriptBlock.outputDescription
    } else {
        ""
    }

    $targetDescription = if ( $scriptBlock.description ) {
        $scriptBlock.description
    } else {
        "This method invokes PowerShell code to perform its function."
    }

    $targetPluginMethodName = if ( $pluginMethodName ) {
        $pluginMethodName
    } else {
        $scriptBlock.name
    }

    $methodParameterList = RenderMethodParameterList $scriptBlock.ParameterTable

    RenderResolvedMethod $scriptBlock.Name $targetPluginMethodName $targetDescription $targetOutputDescription $methodParameterList
}

function RenderResolvedMethod(
    [string] $nativeMethodName,
    [string] $pluginMethodName,
    [string] $description,
    [string] $outputDescription,
    [string] $methodParameterList
)
{
    $descriptionAttributeText ="This PowerShell function's functionality can be described as follows: $($description);The output it returns can be described as follows: $($outputDescription)" -replace "'", "''"

    $descriptionAttribute = "[System.ComponentModel.Description('$descriptionAttributeText')]"

    $kernelAttribute = "[Microsoft.SemanticKernel.KernelFunctionAttribute('$pluginMethodName')]"

    $resolvedMethod =
    @"
    $descriptionAttribute
    $kernelAttribute
    [object] $nativeMethodName( $methodParameterList ) {
        `$parameterList= [System.Collections.Generic.Dictionary[string,object]]::new()
            foreach ( `$parameterName in `$PSBoundParameters.Keys ) {
                `$parameterList.Add(`$parameterName, `$PSBoundParameters[`$parameterName])
            }
        return InvokeFunctionAndReturnAsJson('$nativeMethodName', `$parameterList)
    }
"@

    $resolvedMethod
}

function RenderMethodParameterList(
    [System.Collections.Generic.Dictionary[string,string]] $parameterTable
) {
    $parameterList = foreach ( $parameterName in $parameterTable.Keys ) {
        "[$($parameterTable[$parameterName])] $parameterName"
    }

    $parameterList -join ', '
}

