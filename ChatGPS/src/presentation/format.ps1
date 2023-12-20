#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$ChatResponseType = 'ChatResponse'

function FormatOutput {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true, mandatory=$true)]
        $Response,

        [ScriptBlock] $ResponseBlock,

        [string] $OutputFormat
    )

    begin {}

    process {
        $inputString = if ( $Response.GetType().FullName -eq 'System.Management.Automation.PSCustomObject' ) {
            $Response.Response
        } elseif ( $Response.GetType().FullName -eq 'System.String' ) {
            $Response
        } else {
            throw "Response parameter type '$($Response.GetType())' is not valid -- it must be a string or PSCustomObject"
        }

        $outputResult = if ( $inputString ) {
            if ( $OutputFormat -eq 'MarkDown' ) {
                $InputString | Show-Markdown
            } elseif ( $OutputFormat -eq 'PowerShellEscaped' ) {
                $inputString -replace '`e', "`e"
            } else {
                $inputString
            }
        }

        $finalResponse = if ( $outputResult ) {
            if ( $ResponseBlock ) {
                invoke-command -scriptblock $responseBlock -argumentlist $inputString, $response
            } else {
                $outputResult
            }
        }

        $finalResponse
    }

    end {
    }
}

function ToResponse {
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline=$true, mandatory=$true)]
        [string] $response,

        [string] $role,

        [switch] $AsString
    )

    begin {}

    process {
        if ( $AsString.IsPresent ) {
            $response
        } else {
            HashTableToObject -TypeName ChatResponse -Table @{
                Response = $response
                Role = $role
            }
        }
    }

    end {
    }
}

function GetPassthroughChatParams {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [HashTable] $AllParameters
    )

    $passthroughParameters = @{}

    foreach ( $parameter in
              ( $AllParameters.GetEnumerator() | where Key -in 'OutputFormat', 'NoOutput', 'ResponseBlock' ) ) {
                  $passthroughParameters.Add($parameter.Key, $parameter.Value )
              }

    $passthroughParameters
}

function RegisterTypeData([string] $typeName) {
    remove-typedata -typename $typeName -erroraction ignore

    $coreProperties = $args

    Update-TypeData -force -TypeName $typeName -DefaultDisplayPropertySet $coreProperties
}

function SetObjectType([PSCustomObject] $customObject, [string] $typeName) {
    if ( $customObject.pstypenames -notcontains $typeName ) {
        $customObject.pstypenames.Add($typeName) | out-null
    }
}

function HashtableToObject {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true, valuefrompipeline=$true)]
        [Hashtable] $table,

        [string] $typeName )

    $result = [PSCustomObject] $table

    if ( $typeName ) {
        SetObjectType $result $typeName
    }

    $result
}

RegisterTypeData $script:ChatResponseType Response
