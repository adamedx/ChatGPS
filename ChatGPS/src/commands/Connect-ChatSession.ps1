#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [object[]] @()

function Connect-ChatSession {
    param(
        [parameter(mandatory=$true)]
        [Uri] $ApiEndpoint,

        [parameter(mandatory=$true)]
        [string] $ModelId,

        [parameter(mandatory=$true)]
        [string] $Prompt,

        [parameter(mandatory=$true)]
        [string] $ApiKey
    )

    $options = [Modulus.ChatGPS.Models.AiOptions]::new()

    $options.ApiEndpoint = $ApiEndpoint
    $options.ModelIdentifier = $ModelId
    $options.ApiKey = $ApiKey

    CreateSession $options $Prompt
}
