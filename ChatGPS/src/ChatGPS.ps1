#
# Copyright (c) Adam Edwards
#
# All rights reserved.

set-strictmode -version 2
$erroractionpreference = 'stop'

. (join-path $psscriptroot native.ps1)
. (join-path $psscriptroot services.ps1)
. (join-path $psscriptroot intent.ps1)
. (join-path $psscriptroot presentation.ps1)
. (join-path $psscriptroot shell.ps1)
. (join-path $psscriptroot function.ps1)
. (join-path $psscriptroot config.ps1)
. (join-path $psscriptroot commands.ps1)
