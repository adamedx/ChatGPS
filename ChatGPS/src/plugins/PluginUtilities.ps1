#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#

function GetClassDefinition(
    [string] $pluginName,
    [string] $description,
    [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellPluginFunction]] $scriptTable

) {

    $renderedMethods = RenderClassMethods $scriptTable
    $classDefinition = RenderClassDefinition $pluginName $description $renderedMethods

    $classDefinition
}

function RenderClassDefinition(
    [string] $pluginName,
    [string] $description,
    [string] $renderedMethods
) {
    $invokeScript = GetInvokeScript

    $pluginTemplate = @'
[System.ComponentModel.Description("{2}")]
class {0} : Modulus.ChatGPS.Plugins.PowerShellNativePluginBase {{

    {0}([System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellPluginFunction]] $scriptBlocks) : base("{0}", "{2}", $scriptBlocks) {{ }}

{1}

    [string] $InvokeBlock = {{ {3} }}

}}
'@

    $pluginTemplate -f $pluginName, $renderedMethods, $description, $invokeScript
}

function RenderClassMethods( [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PowerShellPluginFunction]] $methodTable ) {
    $rendered = foreach ( $methodName in $methodTable.Keys ) {
        RenderMethod $methodName $methodTable[$methodName]
    }

    $rendered -join "`n`n"
}

function RenderMethod(
    [string] $pluginMethodName,
    [Modulus.ChatGPS.Plugins.PowerShellPluginFunction] $scriptBlock

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

    $methodParameterList = RenderMethodParameterList $scriptBlock.GetParameterTable()

    RenderResolvedMethod $scriptBlock.Name $targetPluginMethodName $targetDescription $scriptBlock.OutputType $targetOutputDescription $methodParameterList $methodTable[$methodName].ScriptBlock
}

function RenderResolvedMethod(
    [string] $nativeMethodName,
    [string] $pluginMethodName,
    [string] $description,
    [string] $outputType = 'System.String',
    [string] $outputDescription = $null,
    [string] $methodParameterList = $null,
    [string] $methodBlock
) {
    $descriptionAttributeText ="This PowerShell function's functionality can be described as follows: $($description);The output it returns can be described as follows: $($outputDescription)" -replace "'", "''"

    $descriptionAttribute = "[System.ComponentModel.Description('$descriptionAttributeText')]"

    $kernelAttribute = "[Microsoft.SemanticKernel.KernelFunctionAttribute('$pluginMethodName')]"

    $resolvedMethod =
    @"
    $descriptionAttribute
    $kernelAttribute
    [$outputType] $nativeMethodName( $methodParameterList ) {
        `$parameterList= [System.Collections.Generic.Dictionary[string,object]]::new()
         foreach ( `$parameterName in `$PSBoundParameters.Keys ) {
            `$parameterList.Add(`$parameterName, `$PSBoundParameters[`$parameterName])
         }
        `$scriptBlock = `$this.scriptBlocks['$nativeMethodName']
        `$result = try {
            new-item -Path function:Invoke-PowerShellScript -Value `$this.InvokeBlock | out-null
            Invoke-PowerShellScript `$scriptBlock.ScriptBlock `$parameterList
        } catch {
            throw
        }
        return `$result
    }
"@

    $resolvedMethod
}

function RenderMethodParameterList(
    [System.Collections.Generic.Dictionary[string,string]] $parameterTable
) {
    if ( $null -eq $parameterTable ) {
        throw [ArgumentException]::new("Script method parameter table may be empty but can never be set to a null reference.");
    }

    $parameterList = foreach ( $parameterName in $parameterTable.Keys ) {
        "[$($parameterTable[$parameterName])] $parameterName"
    }

    $parameterList -join ', '
}

function Invoke-PowerShellScript {
    param(
    [string] $script,
    [System.Collections.Generic.Dictionary[string,object]] $parameters,
    [int] $timeoutMs = 3600000,
    [bool] $jsonOutput = $false
    )

    [ScriptBlock]::Create($script) | out-null

    $parameterJson = $parameters | convertto-json -compress -depth 5
    $parameterJsonBytes = [System.Text.Encoding]::Unicode.GetBytes($parameterJson)
    $parameterJsonEncoded = [Convert]::ToBase64String($parameterJsonBytes)

    $jsonOutputConverter = $jsonOutput ? ' | convertto-json -compress -depth 5' : ''

    $commandTemplate = 'function prompt {{}};$parameterJsonEncoded = ''{0}''; $parameterJsonBytes = [Convert]::FromBase64String($parameterJsonEncoded); $parameterJson = [System.Text.Encoding]::Unicode.GetString($parameterJsonBytes); $parameters = @{{}}; $parameterObject = $parameterJson | convertfrom-json ; $parameterObject | get-member -membertype noteproperty | foreach {{ $parameters.add($_.name, $parameterObject.$($_.name)) }}; $commandBlock = {{ {1} }}; $result = (& $commandBlock @parameters) {2}; $finalResult = $result | out-string; $bytes = [System.Text.Encoding]::Unicode.GetBytes($finalResult);[Convert]::ToBase64String($bytes);exit'

    $shellCommand = $commandTemplate -f $parameterJsonEncoded, $script, $jsonOutputConverter

    $shellCommandBytes = [System.Text.Encoding]::Unicode.GetBytes($shellCommand)
    $encodedShellCommand = [Convert]::ToBase64String($shellCommandBytes)

    $shellInput = "set-strictmode -version 2;`$decodedCommandBytes = [Convert]::FromBase64String('$encodedShellCommand'); `$decodedCommand = [System.Text.Encoding]::Unicode.GetString(`$decodedCommandBytes); `$decodedCommand | invoke-expression"

    $shellOutput = $shellInput | pwsh -noprofile -noninteractive -nologo -File '-'

    $resultLine = ($shellOutput | select -last 1)

    $decodedBytes = [Convert]::FromBase64String($resultLine)

    [System.Text.Encoding]::Unicode.GetString($decodedBytes)
}

function GetInvokeScript {
    (get-command Invoke-PowerShellScript).ScriptBlock.ToString()
}

function GetGenerationScriptLocation {
    "$psscriptroot/GeneratePlugin.ps1"
}

function GetScriptBlockParameterInfo([ScriptBlock] $scriptBlock) {
    $result = [System.Collections.Generic.Dictionary[string,string]]::new()

    if ( $scriptBlock.ast.ParamBlock -and ( $scriptBlock.ast.ParamBlock | get-member parameters -erroraction ignore ) ) {
        foreach ( $parameter in $scriptBlock.ast.ParamBlock.parameters ) {
            $result.Add($parameter.name, $parameter.StaticType)
        }
    }

    $result
}

function NewPowerShellPluginFunction([string] $methodName, [ScriptBlock] $scriptBlock, [string] $description, [string] $OutputType = 'System.String', [string] $outputDescription = $null) {
    $parameterInfo = GetScriptBlockParameterInfo $scriptBlock

    [Modulus.ChatGPS.Plugins.PowerShellPluginFunction]::new($methodName, $scriptBlock, $parameterInfo, $description, $OutputType, $outputDescription)
}

