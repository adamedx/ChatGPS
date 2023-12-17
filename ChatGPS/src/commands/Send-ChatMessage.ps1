#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Send-ChatMessage {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true, valuefrompipeline=$true)]
        [string] $Message,

        [validateset('None', 'Markdown', 'PowerShellEscaped')]
        [string] $OutputFormat,

        [ScriptBlock] $ResponseBlock,

        [Modulus.ChatGPS.Models.ChatSession]
        $Connection,

        [switch] $NoOutput,

        [switch] $ForceChat
    )

    $targetConnection = if ( $Connection ) {
        $Connection
    } else {
        GetCurrentSession $true
    }

    $response = SendMessage $targetConnection $Message $ForceChat.IsPresent

    if ( ! $NoOutput.IsPresent ) {
        $passthroughParameters = @{}

        foreach ( $parameter in 'OutputFormat', 'ResponseBlock' ) {
            $passthroughParameters.Add( $parameter, $PSBoundParameters[$parameter] )
        }

        $response | FormatOutput @passthroughParameters
    }
}
