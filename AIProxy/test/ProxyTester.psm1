#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

set-strictmode -version 2
$erroractionpreference = 'stop'

. ("$psscriptroot/Start-ProxyRepl.ps1")

export-modulemember -function Start-ProxyRepl
