#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [object[]] @()

function Connect-ChatSession {
    [Modulus.ChatGPS.ChatGPS]::CreateSession() | out-null
}
