#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Remove-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', mandatory=$true, position=0)]
        [Alias('Name')]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [switch] $Force
    )

    begin {
    }

    process {
        $nameOrId = if ( $SessionName ) {
            @{Name=$SessionName}
        } else {
            @{Id=$Id}
        }

        $session = Get-ChatSession @nameOrId

        RemoveSession $session $Force.IsPresent
    }

    end {
    }
}

RegisterSessionCompleter Remove-ChatSession SessionName
