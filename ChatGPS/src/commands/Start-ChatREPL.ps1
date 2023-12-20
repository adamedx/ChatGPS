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
        [string] $OutputFormat = 'None',

        [parameter(valuefrompipeline=$true)]
        $Reply,

        [ScriptBlock] $InputHint = { $userName = $env:USER ? $env:USER : $env:USERNAME; "($($userName)) ChatGPS>" },

        [switch] $HideInitialPrompt,

        [switch] $HideInitialResponse,

        [switch] $HideInputHint,

        [switch] $NoEcho,

        [switch] $NoOutput,

        [switch] $RawOutput,

        [ScriptBlock] $ResponseBlock,

        [ScriptBlock] $ReplyBlock,

        [int32] $MaxReplies = 1,

        [switch] $NoAutoConnect,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection
    )

    begin {
        $currentReplies = $MaxReplies

        $connectionArgument = if ( $Connection ) {
            @{Connection = $Connection}
        } elseif ( ! $NoAutoConnect.IsPresent ) {
            $currentSession = GetCurrentSession
            if ( ! $currentSession ) {
                throw "No current session exists -- please execute Connect-ChatSession and retry"
            }
            @{Connection=$currentSession}
        } else {
            @{}
        }

        $targetResponseBlock = if ( $ResponseBlock ) {
            $ResponseBlock
        } else {
            # See this issue -- this is causing pipeline objects to not output correctly: https://github.com/PowerShell/PowerShell/issues/4594
            {param($responseText, $response) ( $response -eq $null ) ? $responseText : ( $response | format-table -wrap ) }
        }

        $initialResponse = $null

        if ( $InitialPrompt ) {
            $initialResponse = Send-ChatMessage $InitialPrompt @connectionArgument

            if ( ! $HideInitialPrompt.IsPresent ) {
                $conversationTitle = "Conversation: '$InitialPrompt'"
                "`n$($conversationTitle)" | write-host -foregroundcolor cyan
                ( '-' * $conversationTitle.Length ) | write-host -foregroundcolor cyan
            }
        }

        $inputHintArgument = if ( ! $HideInputHint.IsPresent -and ! $NoEcho.IsPresent ) {
            @{Prompt=$InputHint}
        } else {
            @{}
        }

        $lastResponse = $initialResponse

        if ( $initialResponse -and ! $HideInitialResponse.IsPresent -and ! $NoOutput.IsPresent ) {
            FormatOutput -Response $initialResponse -OutputFormat $OutputFormat -ResponseBlock $targetResponseBlock
        }
    }

    process {

        while ( $true ) {
            $inputHintValue = if ( $InputHintArgument.Count -gt 0 ) {
                Invoke-Command -scriptblock $InputHintArgument.Prompt
            }

            $dynamicInputHintArgument = if ( $inputHintValue ) {
                @{Prompt = $inputHintValue}
            } else {
                @{}
            }

            $replyText = if ( $ReplyBlock -and ( $currentReplies -ne 0 ) ) {
                $replyData = GetChatReply -SourceMessage $lastResponse -ReplyBlock $ReplyBlock -MaxReplies $currentReplies

                if ( $replyData ) {
                    if ( $inputHintValue ) {
                        Write-Host "$($InputHintValue): " -nonewline
                        Write-Host $replyData.Reply
                    }
                    $currentReplies = $replyData.nextMax
                    $replyData.Reply
                }
            }

            $inputText = if ( ! $replyText ) {
                Read-Host @dynamicInputHintArgument
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

            $result = Send-ChatMessage $inputText -ForceChat:$forceChat @connectionArgument -OutputFormat $OutputFormat -RawOutput:$RawOutput.IsPresent

            $lastResponse = $result

            if ( $result ) {
                FormatOutput -Response $result -ResponseBlock $targetResponseBlock -OutputFormat $OutputFormat
            }
        }
    }

    end {
    }
}
