#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', position=0)]
        $Name,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [parameter(parametersetname='current', mandatory=$true)]
        [switch] $Current
    )

    if ( $Current.IsPresent ) {
        GetCurrentSession
    } else {
        $sessions = GetChatSessions | where {
            ( $null -eq $Id -and $null -eq $Name ) -or
            ( $_.Name -eq $Name ) -or
            ( $_.Id -eq $Id )
        }

        if ( ! $sessions ) {
            if ( $Id ) {
                throw [ArgumentException]::new("The session with the specified id '$Id' could not be found.")
            } elseif ( $Name ) {
                throw [ArgumentException]::new("The session with the specified name '$Name' could not be found.")
            }
        }

        $sessions | where { !! $_.name } | sort-object Name
        $sessions | where { ! $_.name }
    }
}
