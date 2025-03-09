#
# Copyright (c) Adam Edwards
#
# All rights reserved.

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
