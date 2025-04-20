#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

$welcomeShown = $false

function ShowWelcome([bool] $hideWelcome) {
    if ( ! $hideWelcome -and ! $script:welcomeShown ) {
        $script:welcomeShown = $true
        $module = $myinvocation.mycommand.Module
        $moduleName = $module.Name
        $version = $module.Version
        $welcomeMessage = "`nWelcome to $moduleName Shell $version!`n"

        write-host -foreground green $welcomeMessage
        write-host -foreground cyan "$([DateTime]::now.ToString('F'))`n"
        write-host " * View configuration at $(GetDefaultSettingsLocation)"
        write-host " * Enter '.help' for a list of built-in shell commands"
    }
}
