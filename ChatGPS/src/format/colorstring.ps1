#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$colorEscapeChar = "$([char]0x1b)"
$colorEndChar = "$($colorEscapeChar)[0m"

# Note that this function is invoked in the format ps1xml,
# and those scriptblocks are outside the scope of this module
# where this function is defined. As a result, a scriptblock
# of the module must
function HighlightText([string]$text, [int] $colorValue) {
    if ( $global:host.ui.SupportsVirtualTerminal -and $text ) {
        $background = 40 + $colorValue
        "$($script:colorEscapeChar)[" + "$($background.ToString())m" + $text + $script:colorEndChar
    } else {
        $text
    }
}

