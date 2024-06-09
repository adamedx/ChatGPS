#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$ChatResponseTypeName = 'Modulus.ChatGPS.PowerShell.ChatResponse'

function TransformResponseText {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true, mandatory=$true)]
        [PSCustomObject] $Response,

        [ScriptBlock] $ResponseBlock,

        [string] $OutputFormat
    )

    begin {}

    process {
        $inputString = $Response.Response

        $outputResult = if ( $inputString ) {
            if ( $OutputFormat -eq 'MarkDown' ) {
                $InputString | Show-Markdown
            } elseif ( $OutputFormat -eq 'PowerShellEscaped' ) {
                $inputString -replace '`e', "`e"
            } else {
                $inputString
            }
        }

        if ( $outputResult ) {
            if ( $ResponseBlock ) {
                invoke-command -scriptblock $responseBlock -argumentlist $outputResult, $response
            } else {
                $outputResult
            }
        }
    }

    end {
    }
}

function ToResponse {
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline=$true, mandatory=$true)]
        [object] $response,
        [string] $role,
        [DateTime] $received,
        [switch] $AsString
    )

    begin {}

    process {
        if ( $AsString.IsPresent ) {
            $response
        } else {
            HashTableToObject -TypeName $ChatResponseTypeName -Table @{
                Received = $received
                Role = $role
                Response = $response
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
        $customObject.pstypenames.Insert(0, $typeName) | out-null
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

