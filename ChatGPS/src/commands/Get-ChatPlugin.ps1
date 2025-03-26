#
# Copyright (c) Adam Edwards
#
# All rights reserved.


function Get-ChatPlugin {
    [cmdletbinding(positionalbinding=$false, defaultparametersetname='availableplugins')]
    param(
        [parameter(parametersetname='bysession', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Modulus.ChatGPS.Models.ChatSession] $Session,

        [parameter(parametersetname='currentsession', mandatory=$true)]
        [switch] $CurrentSession
    )
    begin {
        $currentSessionInternal = if ( $CurrentSession.IsPresent ) {
            Get-ChatSession -Current
        }
    }

    process {
        $targetSession = if ( $currentSessionInternal ) {
            $currentSessionInternal
        } elseif ( $Session )  {
            $Session
        }

        if ( ! $targetSession ) {
            [Modulus.ChatGPS.Plugins.Plugin]::GetPlugins() | sort-object Name
        } else {
            $targetSession.Plugins | sort-object Name
        }
    }

    end {
    }
}
