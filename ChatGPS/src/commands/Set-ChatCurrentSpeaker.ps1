#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Set-ChatCurrentSpeaker {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true,valuefrompipeline=$true)]
        [PSCustomObject] $Speaker
    )
    SetCurrentSpeaker $Speaker
}
