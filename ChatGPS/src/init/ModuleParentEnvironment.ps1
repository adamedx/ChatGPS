#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

# This scriptblock is outside of the module, it is dot-sourced
# into the environment of the caller that imported the module
# via ScriptsToProcess in the module manifest. Because of this,
# it can be used to work around the fact that any functions created
# by code hosted within the module are not visible outside of the module.
$__ChatGPS_ModuleParentFunctionBuilder = {
    param(
        [parameter(mandatory=$true)]
        [string] $functionName,

        [parameter(mandatory=$true)]
        [scriptblock] $scriptBlock,

        [boolean] $force = $false
    )

    new-item -path function:\ -name $functionName -Value $scriptBlock -Force:$force
}
