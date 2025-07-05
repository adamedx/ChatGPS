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


function New-ChatSettings {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(position=0)] [string] $SettingsFilePath = $null,

        [string] $ProfileName = 'Profile0',

        [switch] $PassThru,

        [switch] $NoSession,

        [switch] $NoWrite,

        [switch] $NoProfile,

        [switch] $Force
    )

    $targetPath = if ( $SettingsFilePath ) {
        $SettingsFilePath
    } else {
        GetDefaultSettingsLocation
    }

    if ( ! $NoWrite.IsPresent ) {
        if ( $targetPath -and ( test-path $targetPath ) -and ! $Force.IsPresent ) {
            write-error "The specified settings file at '$SettingsFilePath' already exists; use the Force option to force this command to overwrite the existing settings"
        }
    }

    $settings = [RootSettings]::new()

    $settings.generatedDate = [DateTimeOffset]::Now.ToString()
    $settings.generatedTool = 'ChatGPS New-ChatSettings'

    $settings.profiles = [ProfileSettings]::new()
    $settings.profiles.defaults = [Profile]::new()
    $settings.profiles.list = [System.Collections.Generic.List[Profile]]::new()

    if ( ! $NoProfile.IsPresent ) {
        $settings.defaultProfile = $ProfileName
        $settings.profiles.list.Add([Profile]::new())
        $settings.profiles.list[0].name = $ProfileName
    }

    $settings.sessions = [SessionSettings]::new()
    $settings.models = [ModelResourceSettings]::new()
    $settings.customPlugins = [CustomPluginResourceSettings]::new()

    if ( ! $NoSession.IsPresent ) {
        $settings.models.list = [System.Collections.Generic.List[ModelResource]]::new()
        $settings.models.list.Add([ModelResource]::new())
        $settings.models.list[0].name = 'Model0'

        $settings.sessions.defaults = [ModelChatSession]::new()
        $settings.sessions.list = [System.Collections.Generic.List[ModelChatSession]]::new()
        $settings.sessions.list.Add([ModelChatSession]::new())
        $settings.sessions.list[0].name = 'Session0'
        $settings.sessions.list[0].modelName = $settings.models.list[0].name
    }

    $jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
    $jsonOptions.WriteIndented = $true
    $jsonOptions.MaxDepth = 5

    $content = [System.Text.Json.JsonSerializer]::Serialize[RootSettings]($settings, $jsonOptions)

    if ( $PassThru.IsPresent -or $NoWrite.IsPresent ) {
        $settings
    }

    if ( ! $NoWrite.IsPresent ) {
        $content | out-file $targetPath
    }
}
