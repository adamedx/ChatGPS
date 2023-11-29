#
# Copyright (c) Adam Edwards
#
# All rights reserved.

Describe 'Connect-ChatSession command' {
    Context 'When executing the Connect-ChatSession command' {
        It "should not throw an exception when executed with no parameters" {
            { Connect-ChatSession } | Should -Not -Throw
        }
    }
}
