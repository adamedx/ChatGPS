#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

function Add-ChatPluginFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [PowerShellKernelPluginBuilder] $Plugin,

        [parameter(position=0, mandatory=$true)]
        [string] $FunctionName,

        [parameter(position=1, mandatory=$true)]
        [ScriptBlock] $ScriptBlock,

        [parameter(position=2)]
        [string] $OutputType = 'System.String',

        [string] $Description,

        [string] $OutputDescription,

        [switch] $NoOutput
    )

    $targetDescription = if ( $Description ) {
        $Description
    } else {
        "This method invokes PowerShell code to perform its function."
    }

    $targetPlugin = if ( $Plugin ) {
        $Plugin
    } else {
        [PowerShellKernelPluginBuilder]::new()
    }

    $targetPlugin.AddMethod($FunctionName, $ScriptBlock, $Description, $OutputType, $OutputDescription)

    if ( ! $NoOutput.IsPresent ) {
        $targetPlugin
    }
}
