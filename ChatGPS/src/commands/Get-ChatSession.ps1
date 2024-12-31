#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatSession {
    [cmdletbinding(positionalbinding=$false)]
    param()

    GetCurrentSession
}
