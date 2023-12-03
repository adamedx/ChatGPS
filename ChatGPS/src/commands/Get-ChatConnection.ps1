#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatConnection {
    [cmdletbinding(positionalbinding=$false)]
    param()

    GetCurrentSession
}
