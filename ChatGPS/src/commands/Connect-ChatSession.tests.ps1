#
# Copyright (c) Adam Edwards
#
# All rights reserved.

InModuleScope ChatGPS {
    Describe 'Connect-ChatSession command' {
        BeforeAll {

            # Use this to load the Semantic Kernel dependencies, otherwise
            # references to Semantic Kernel types will not work -- this is true
            # even when using Pester's InModuleScope enclosing scriptblock
            try {
                [Modulus.ChatGPS.Models.ChatSession]::new() | out-null
            } catch {
            }

            # PowerShell will try to resolve type names in the script before execution,
            # so create the type dynamically by defining the string representation of the
            # script block and generating a real script block to subsequently execute.
            . ([ScriptBlock]::Create(
@'
class MockChatService : Modulus.ChatGPS.Services.IChatService {
    [Microsoft.SemanticKernel.AI.ChatCompletion.ChatHistory] CreateChat([string] $prompt) {
        return [Microsoft.SemanticKernel.AI.ChatCompletion.ChatHistory]::new()
    }
}
'@
               ))

            Mock CreateSession {param( $Options, $Prompt) [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt, [MockChatService]::new()) } -Verifiable
        }

        Context 'When executing the Connect-ChatSession command' {

            It "should not throw an exception when executed with no parameters" {
                { Connect-ChatSession https://api.ai.mocked.com gpt35 "Don't be evil." apikey123456789mock } | Should -Not -Throw
                Should -Invoke -CommandName CreateSession
            }
        }
    }
}
