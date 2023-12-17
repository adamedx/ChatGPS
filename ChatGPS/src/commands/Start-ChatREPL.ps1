#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Start-ChatREPL {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)]
        [string] $InitialPrompt,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat,

        [parameter(valuefrompipeline=$true)]
        $Reply,

        [string] $InputHint = 'ChatGPS>',

        [switch] $HideInitialPrompt,

        [switch] $HideInitialResponse,

        [switch] $HideInputHint,

        [switch] $NoEcho,

        [switch] $NoOutput,

        [ScriptBlock] $ResponseBlock,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection
    )

    begin {
        $connectionArgument = if ( $Connection ) {
            @{Connection = $Connection}
        } else {
            @{}
        }

        $initialResponse = if ( $InitialPrompt ) {
            Send-ChatMessage $InitialPrompt @connectionArgument

            if ( ! $HideInitialPrompt.IsPresent ) {
                $InitialPrompt | FormatOutput -OutputFormat $OutputFormat
            }
        }

        $inputHintArgument = if ( ! $HideInputHint.IsPresent -and ! $NoEcho.IsPresent ) {
            @{Prompt=$InputHint}
        } else {
            @{}
        }

        if ( $initialResponse -and ! $HideInitialResponse.IsPresent -and ! $NoOutput.IsPresent ) {
            $outputArgument = @{}

            if ( $OutputFormat ) {
                $outputArgument = @{OutputFormat=$OutputFormat}
            }

            $initialResponse | FormatOutput @outputFormat
        }

        $passthroughParameters = @{}

        foreach ( $parameter in 'OutputFormat', 'ResponseBlock' ) {
            if ( $PSBoundParameters[$parameter] ) {
                $passthroughParameters.Add( $parameter, $PSBoundParameters[$parameter] )
            }
        }
    }

    process {

        while ( $true ) {

            $inputText = Read-Host @InputHintArgument

            $forceChat = $false

            if ( $inputText.Trim() -eq '.exit' ) {
                break
            } elseif ( $inputText.Trim().StartsWith('.chat ') ) {
                $keywordLength = '.chat '.Length
                $inputText = $inputText.SubString($keywordLength, $inputText.Length - $keywordLength)
                $forceChat = $true
            }

            Send-ChatMessage $inputText -ForceChat:$forceChat @connectionArgument @passthroughParameters
        }
    }

    end {
    }
}
