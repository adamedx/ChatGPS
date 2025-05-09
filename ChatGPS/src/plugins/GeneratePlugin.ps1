[cmdletbinding(positionalbinding=$false)]
param(
    [parameter(mandatory=$true)]
    [string] $Name,
    [string] $Description,
    $Scripts
)
set-strictmode -version 2

. "$psscriptroot/PowerShellScriptBlock.ps1"
. "$psscriptroot/PluginUtilities.ps1"

$definition = GetClassDefinition $Name $Description $Scripts

$creationBlock = [ScriptBlock]::Create(
    "param(`$scripts) $definition; [$Name]::new(`$scripts)" )

$result = $creationBlock.InvokeReturnAsIs($Scripts)

$wrapper = [System.Collections.Generic.Dictionary[string,object]]::new()
$wrapper.Add('result', $result)
$wrapper

