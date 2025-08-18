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

function WarnPluginCompatibility([Modulus.ChatGPS.Models.ChatSession] $session, [string] $pluginName) {
    if ( $session.AiOptions.Provider -eq 'Anthropic' ) {
        write-warning "Plugin '$pluginName' has been added to session '$($session.Name)' which uses an Anthropic model; plugins may not currently be supported by the Anthropic provider."
    }
}
