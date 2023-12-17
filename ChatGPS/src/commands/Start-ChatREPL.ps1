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

        [ScriptBlock] $ReplyBlock,

        [int32] $MaxReplies = 1,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection
    )

    begin {
        $currentReplies = $MaxReplies

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

        $lastResponse = $inputHintArgument.Prompt

        $outputParameters = @{}

        foreach ( $parameter in 'OutputFormat', 'ResponseBlock' ) {
            if ( $PSBoundParameters[$parameter] ) {
                $outputParameters.Add( $parameter, $PSBoundParameters[$parameter] )
            }
        }
    }

    process {

        while ( $true ) {

            $replyText = if ( $ReplyBlock -and ( $currentReplies -ne 0 ) ) {
                $replyData = GetChatReply -SourceMessage $lastResponse -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

                if ( $replyData ) {
                    if ( $InputHintArgument.Count -gt 0 ) {
                        Write-Host "$($InputHintArgument['Prompt']): " -nonewline
                        Write-Host $replyData.Reply
                    }
                    $currentReplies = $replyData.nextMax
                    $replyData.Reply
                }
            }

            $inputText = if ( ! $replyText ) {
                Read-Host @InputHintArgument
            } else {
                $replyText
            }

            $forceChat = $false

            if ( ( ! $inputText ) -or ( $inputText.Trim() -eq '.exit' ) ) {
                break
            } elseif ( $inputText.Trim().StartsWith('.chat ') ) {
                $keywordLength = '.chat '.Length
                $inputText = $inputText.SubString($keywordLength, $inputText.Length - $keywordLength)
                $forceChat = $true
            }

            $result = Send-ChatMessage $inputText -ForceChat:$forceChat @connectionArgument

            $lastResponse = $result

            if ( $result ) {
                 $result | FormatOutput @outputParameters
            }
        }
    }

    end {
    }
}
