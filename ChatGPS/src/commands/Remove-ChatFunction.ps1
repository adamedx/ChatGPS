#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function Remove-ChatFunction {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', ValueFromPipelineByPropertyName=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', position=0, mandatory=$true)]
        [string] $Name
    )

    begin {
        $functions = GetFunctionInfo
    }

    process {
        $targetId = if ( $Name ) {
            $functions.GetFunctionByName($Name).Id
        } else {
            $Id
        }

        $functions.RemoveFunction($targetId)
    }

    end {
    }
}

[Function]::RegisterFunctionNameCompleter('Remove-ChatFunction', 'Name')
