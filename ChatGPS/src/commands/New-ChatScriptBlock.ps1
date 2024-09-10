#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#
function New-ChatScriptBlock {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='id', valuefrompipelinebypropertyname=$true, mandatory=$true)]
        [Guid] $Id,

        [parameter(parametersetname='name', mandatory=$true)]
        [Alias('Name')]
        [string] $FromChatFunctionName,

        [parameter(parametersetname='createnew', position=0, mandatory=$true)]
        [string] $Definition,

        [string] $InputObjectParameterName,

        [switch] $NoInputObject,

        [string] $BindToFunctionName,

        [switch] $Force,

        [Modulus.ChatGPS.Models.ChatSession] $Connection
    )

    $targetConnection = if ( $Connection ) {
        $Connection
    } else {
        GetCurrentSession $true
    }

    $sessionFunctions = $targetConnection.SessionFunctions

    $functionSpecifier = $null

    $function = if ( $FromChatFunctionName ) {
        $functionSpecifier = "-Name '$FromChatFunctionName'"
        $sessionFunctions.GetFunctionByName($FromChatFunctionName)
    } else {
        $functionById = if ($Id) {
            $sessionFunctions.GetFunctionById($Id)
        } else {
            New-ChatFunction $Definition
        }
        $functionSpecifier = "-Id $($functionById.Id)"
        $functionById
    }

    $firstParameter = $true

    # By default, we want the first parameter to come from pipeline input as a usability
    # enhancement, but the user can turn this off or specify a different parameter to take the input
    $argumentList = $function.Parameters.Keys | foreach {
        if ( $NoInputObject.IsPresent -or ( ! $firstParameter -and $_ -ne $InputObjectParameterName ) ) {
            "`$$_"
        } else {
            "[parameter(valuefrompipeline=`$true)] `$$_"
        }
        $firstParameter = $false
    } 

    $argumentString = $argumentList | Join-string -Separator ','

    # The cast of PSBoundParameters to HashTable is required because apparently it has a different
    # type at different times with different casting behavior
    $scriptBlock = [ScriptBlock]::Create(
@"
        param( $argumentString )
        Invoke-ChatFunction $functionSpecifier -Parameters ([HashTable] `$PSBoundParameters)
"@
                                        )
    if ( $BindToFunctionName ) {
        . $__ChatGPS_ModuleParentFunctionBuilder $BindToFunctionName $scriptBlock $Force.IsPresent
    } else {
        $scriptBlock
    }
}

[Function]::RegisterFunctionNameCompleter('New-ChatScriptBlock', 'BindToFunctionName')
