#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function CreateSession {
    param(
        [parameter(mandatory=$true)]
        [Modulus.ChatGPS.Models.AiOptions] $Options,

        [parameter(mandatory=$true)]
        [string] $Prompt
    )

    [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt)
}
