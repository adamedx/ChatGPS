#
# Copyright (c), Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


InModuleScope ChatGPS {
    Describe 'Connect-ChatSession command' {
        BeforeAll {

            # Use this to load the Semantic Kernel dependencies, otherwise
            # references to Semantic Kernel types will not work -- this is true
            # even when using Pester's InModuleScope enclosing scriptblock
            try {
#                [Modulus.ChatGPS.Models.ChatSession]::new($null, $null, 'None', $null, $null) | out-null
            } catch {
            }
<#
            # PowerShell will try to resolve type names in the script before execution,
            # so create the type dynamically by defining the string representation of the
            # script block and generating a real script block to subsequently execute.
            . ([ScriptBlock]::Create(
@'
class MockChatService : Modulus.ChatGPS.Plugins.PluginTable { # , Modulus.ChatGPS.Services.IChatService {
    # Need to restore inheritance from IChatService interface
    MockChatService() : base( $null ) {}
    [Microsoft.SemanticKernel.ChatCompletion.ChatHistory] CreateChat([string] $prompt) {
        return [Microsoft.SemanticKernel.ChatCompletion.ChatHistory]::new()
    }
    [System.Threading.Tasks.Task[System.Collections.Generic.IReadOnlyList[Microsoft.SemanticKernel.ChatMessageContent]]] GetChatCompletionAsync([Microsoft.SemanticKernel.ChatCompletion.ChatHistory] $history, [bool] $allowAgentAccess = $null) {
        return $null
    }
    [System.Threading.Tasks.Task[Modulus.ChatGPS.Models.FunctionOutput]] InvokeFunctionAsync([string] $definitionPrompt, [System.Collections.Generic.Dictionary[string,object]] $parameters, [bool] $allowFunctionCall) {
        return $null
    }

    [Modulus.ChatGPS.Models.AiOptions] get_ServiceOptions() {
        return $null
    }
}
'@
               ))
#>
#            Mock CreateSession {param( $Options, $Prompt) [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $Prompt, [MockChatService]::new()) } -Verifiable
        }

        Context 'When executing the Connect-ChatSession command' {

            It "should not throw an exception when executed with basic parameters" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelidentifier gpt35 -customsystemprompt "Don't be evil." -apikey apikey123456789mock -NoConnect } | Should -Not -Throw
            }

            It "should not throw an exception when executed with a conversational system prompt" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelidentifier gpt35 -customsystemprompt "Don't be evil." -apikey apikey123456789mock -NoConnect -SystemPromptId Conversational } | Should -Not -Throw
            }

            It "should not throw an exception when executed with a prompt with function invocation" {
                { Connect-ChatSession -ApiEndpoint https://api.ai.mocked.com -modelidentifier gpt35 -customsystemprompt "Echo 'Hello World' to the terminal." -apikey apikey123456789mock -NoConnect -SystemPromptId PowerShellStrict } | Should -Not -Throw
            }
        }
    }
}
