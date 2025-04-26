#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Select-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', mandatory=$true, position=0)]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id
    )

    $nameOrId = if ( $SessionName ) {
        @{Name=$SessionName}
    } else {
        @{Id=$Id}
    }

    $session = Get-ChatSession @nameOrId

    SetCurrentSession $session
}

RegisterSessionCompleter Select-ChatSession SessionName
RegisterSessionCompleter Select-ChatSession Id
