#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Connect-ChatSession {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0, mandatory=$true)]
        [string] $Prompt,

        [parameter(mandatory=$true)]
        [Uri] $ApiEndpoint,

        [parameter(mandatory=$true)]
        [string] $ModelId,

        [parameter(mandatory=$true)]
        [string] $ApiKey,

        [switch] $NoSetCurrent
    )

    $options = [Modulus.ChatGPS.Models.AiOptions]::new()

    $options.ApiEndpoint = $ApiEndpoint
    $options.ModelIdentifier = $ModelId
    $options.ApiKey = $ApiKey

    CreateSession $options $Prompt -SetCurrent:(!$NoSetCurrent.IsPresent)
}
