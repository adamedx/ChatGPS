#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function FormatOutput {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(valuefrompipeline=$true)]
        [string] $InputString,

        [ScriptBlock] $ResponseBlock,

        [string] $OutputFormat
    )

    $outputResult = if ( $InputString ) {
        if ( $OutputFormat -eq 'MarkDown' ) {
            $InputString | Show-Markdown
        } elseif ( $OutputFormat -eq 'PowerShellEscaped' ) {
            "$InputString"
        } else {
            $InputString
        }
    }

    if ( $outputResult ) {
        if ( $ResponseBlock ) {
            invoke-command -scriptblock $responseBlock -argumentlist $outputResult
        } else {
            $outputResult
        }
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
                  $replyParams.Add($parameter.Key, $parameter.Value )
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
        $customObject.pstypenames.Add($typeName)
    }
}

function HashTableToObject( [Hashtable] $table, [string] $typeName ) {
    $result = [PSCustomObject] $table

    if ( $typeName ) {
        SetObjectType $result $typeName
    }

    $result
}
