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
