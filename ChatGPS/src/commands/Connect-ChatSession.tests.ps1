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
                [Modulus.ChatGPS.Models.ChatSession]::new($null, $null, 'None', $null, $null) | out-null
            } catch {
            }

            # PowerShell will try to resolve type names in the script before execution,
            # so create the type dynamically by defining the string representation of the
            # script block and generating a real script block to subsequently execute.
            . ([ScriptBlock]::Create(
@'
class MockChatService : Modulus.ChatGPS.Services.IChatService {
    [Microsoft.SemanticKernel.ChatCompletion.ChatHistory] CreateChat([string] $prompt) {
        return [Microsoft.SemanticKernel.ChatCompletion.ChatHistory]::new()
    }
    [System.Threading.Tasks.Task[System.Collections.Generic.IReadOnlyList[Microsoft.SemanticKernel.ChatMessageContent]]] GetChatCompletionAsync([Microsoft.SemanticKernel.ChatCompletion.ChatHistory] $history) {
        return $null
    }
    [System.Threading.Tasks.Task[Modulus.ChatGPS.Models.FunctionOutput]] InvokeFunctionAsync([string] $definitionPrompt, [System.Collections.Generic.Dictionary[string,object]] $parameters) {
        return $null
    }
}
'@
               ))

#            Mock CreateSession {param( $Options, $Prompt) [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt, [MockChatService]::new()) } -Verifiable
        }

        Context 'When executing the Connect-ChatSession command' {

            It "should not throw an exception when executed with basic parameters" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelid gpt35 -prompt "Don't be evil." -apikey apikey123456789mock -NoConnect } | Should -Not -Throw
#                Should -Invoke -CommandName CreateSession
            }

            It "should not throw an exception when executed with a conversational system prompt" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelid gpt35 -prompt "Don't be evil." -apikey apikey123456789mock -NoConnect -SystemPromptId Conversational } | Should -Not -Throw
            }

            It "should not throw an exception when executed with a prompt with function invocation" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelid gpt35 -prompt "Echo 'Hello World' to the terminal." -apikey apikey123456789mock -NoConnect -SystemPromptId PowerShellStrict } | Should -Not -Throw
            }
        }
    }
}
