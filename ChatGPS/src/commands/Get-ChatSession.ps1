#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatSession {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='byname')]
    param(
        [parameter(parametersetname='byname', position=0)]
        [Alias('Name')]
        $SessionName,

        [parameter(parametersetname='byid', mandatory=$true, valuefrompipelinebypropertyname=$true)]
        $Id,

        [parameter(parametersetname='current', mandatory=$true)]
        [switch] $Current
    )

    if ( $Current.IsPresent ) {
        GetCurrentSession
    } else {
        $sessions = GetChatSessions | where {
            ( $null -eq $Id -and $null -eq $SessionName ) -or
            ( $_.Name -eq $SessionName ) -or
            ( $_.Id -eq $Id )
        }

        if ( ! $sessions ) {
            if ( $Id ) {
                write-error "The session with the specified id '$Id' could not be found."
            } elseif ( $SessionName ) {
                write-error "The session with the specified name '$SessionName' could not be found."
            }
        }

        $sessions | where { !! $_.name } | sort-object Name
        $sessions | where { ! $_.name }
    }
}

RegisterSessionCompleter Get-ChatSession SessionName
RegisterSessionCompleter Get-ChatSession Id
