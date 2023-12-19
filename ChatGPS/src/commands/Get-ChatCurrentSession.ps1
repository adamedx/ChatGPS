#
# Copyright (c) Adam Edwards
#
# All rights reserved.

function Get-ChatCurrentSession {
    [cmdletbinding(positionalbinding=$false)]
    param()
    GetCurrentSession
}
