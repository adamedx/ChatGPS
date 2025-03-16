#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Select-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', mandatory=$true, position=0)]
        $Name,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id
    )

    $nameOrId = if ( $Name ) {
        @{Name=$Name}
    } else {
        @{Id=$Id}
    }

    $session = Get-ChatSession @nameOrId

    SetCurrentSession $session
}

RegisterSessionCompleter Select-ChatSession Name
RegisterSessionCompleter Select-ChatSession Id
