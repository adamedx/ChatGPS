#
# Copyright (c) Adam Edwards
#
# All rights reserved.

$Sessions = [ordered] @{}
$CurrentSession = $null

$__ModuleVersionString = {}.Module.Version.ToString()

function GetUserAgent {
    $osversion = [System.Environment]::OSVersion.version.tostring()
    $platform = 'Windows NT'
    $os = 'Windows NT'
    if ( $PSVersionTable.PSEdition -eq 'Core' ) {
        if ( ! $PSVersionTable.OS.contains('Windows') ) {
            $platform = $PSVersionTable.Platform
            if ( $PSVersionTable.OS.contains('Linux') ) {
                $os = 'Linux'
            } else {
                $os = [System.Environment]::OSVersion.Platform
            }
        }
    }
    $language = [System.Globalization.CultureInfo]::CurrentCulture.name
    'Modulus-ChatGPS/{5} PowerShell/{4} ({0}; {1} {2}; {3})' -f $platform, $os, $osversion, $language, $PSVersionTable.PSversion, $__ModuleVersionString
}

function CreateSession {
    param(
        [parameter(mandatory=$true)]
        [Modulus.ChatGPS.Models.AiOptions] $Options,

        [parameter(mandatory=$true)]
        [string] $Prompt,

        [string] $AiProxyHostPath = $null,

        [string] $LogDirectory = $null,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel = 'Default',

        [switch] $SetCurrent,

        [validateset('None','Truncate', 'Summarize')]
        [string] $TokenStrategy = 'Truncate',

        [switch] $NoConnect,

        [int] $HistoryContextLimit = -1,

        [ScriptBlock] $SendBlock = $null,

        [ScriptBlock] $ReceiveBlock = $null,

        [string] $Name = $null,

        [string] $UserAgent,

        [switch] $NoSave,

        [switch] $Force,

        [HashTable] $Plugins,

        $BoundParameters
    )

    $targetLogDirectory = if ( $LogDirectory ) {
        (Get-Item $LogDirectory).FullName
    }

    $context = @{
        SendBlock = $SendBlock
        ReceiveBlock = $ReceiveBlock
        Options = $Options
    }

    $targetUserAgent = if ( $UserAgent ) {
        $UserAgent
    } else {
        GetUserAgent
    }

    $session = [Modulus.ChatGPS.ChatGPS]::CreateSession($Options, $AiProxyHostPath, $Prompt, $TokenStrategy, $targetLogDirectory, $LogLevel, $null, $HistoryContextLimit, $context, $Name, $targetUserAgent)

    TestSession $session $Options $NoConnect.IsPresent

    $sessionSettings = GetExplicitSessionSettingsFromSessionParameters $session $BoundParameters

    ConfigureSessionPlugins $Plugins

    AddSession $session $SetCurrent.IsPresent $NoSave.IsPresent $Force.IsPresent $sessionSettings

    $session
}

function TestSession($session, [Modulus.ChatGPS.Models.AiOptions] $originalAiOptions, [bool] $noConnect) {
    if ( $Session.IsRemote -and ! $noConnect ) {
        try {
            SendConnectionTestMessage $session
        } catch {
            $exceptionMessage = if ( $_.Exception.InnerException ) {
                $_.Exception.InnerException.Message
            } else {
                $_.Exception.Message
            }

            $apiEndpoint = $originalAiOptions.ApiEndpoint

            $apiEndpointAdvice = if ( $apiEndpoint ) {
                "Ensure that the remote API URI '$($apiEndpoint)' is accessible from this device."
            } else {
                "Ensure that you have network connectivity to the remote service hosting the model."
            }

            $signinAdvice = if ( $originalAiOptions.ApiKey ) {
                'Also ensure that the specified API key is valid for the given model API URI.'
            } else {
                'Also ensure that you have signed in using a valid identity that has been granted access to the given model API URI. ' +
                '(e.g. for Azure OpenAI models try signing out with Logout-AzAccount, then retry the command, or explicitly use ' +
                'LoginAzAccount to sign in as the correct identity). You can also specify the AllowInteractiveSignin parameter with ' +
                'with this command and retry if you do not have access to signin tools for the remote model; this may result in ' +
                'multiple requests to re-authenticate.'
            }
            throw [ApplicationException]::new("Attempt to establish a test connection to the remote model failed.`n" +
                                              "$($apiEndpointAdvice)`n" +
                                              "$($signinAdvice)`nSpecify the NoConnect option to skip this test when invoking this command.`n" +
                                              "$($exceptionMessage)", $_.Exception)
        }
    }
}

function ConfigureSessionPlugins([HashTable] $parametersByPlugin) {
    if ( $parametersByPlugin ) {
        foreach ( $pluginName in $parametersByPlugin.Keys ) {
            $parameterTable = $parametersByPlugin[$pluginName]

            $parameterInfo = GetPluginParameterInfo $pluginName $parameterTable

            $session.AddPlugin($pluginName, $parameterInfo)
        }
    }
}

function AddSession($session, [bool] $setCurrent = $false, [bool] $noSave = $false, [bool] $forceOnNameCollision, $sourceSettings = $null) {
    if ( ! $noSave ) {
        if ( $name ) {
            if ( $script:sessions.Count -gt 0 ) {
                $existing = $script:sessions.Values.Session | where Name -eq $name

                if ( $existing ) {
                    if ( $forceOnNameCollision ) {
                        RemoveSession $existing $true
                    } else {
                        throw [ArgumentException]::new("A session named '$name' already exists.")
                    }
                }
            }
        }

        $sessionInfo = [PSCustomObject] @{
            Session = $session
            SourceSettings = $sourceSettings
        }

        $script:sessions.Add($session.Id, $sessionInfo)
    }

    if ( $setCurrent ) {
        $script:CurrentSession = $session
    }
}

function RemoveSession($session, $allowRemoveCurrent) {
    $current = GetCurrentSession

    $isCurrentSession = $current -and ( $current.id -eq $session.id )

    if ( $isCurrentSession -and ! $allowRemoveCurrent ) {
        throw [InvalidOperationException]::new("The session with identifier '$($session.Id)' may not be removed because it is the current active session.")
    }

    $script:sessions.Remove($session.Id)

    if ( $isCurrentSession ) {
        $script:CurrentSession = if ( $script:sessions.Count -gt 0 ) {
            $script:sessions.Values.Session | select-object -first 1
        }
    }
}

function UpdateSession($session, $settingsInfo) {
    $script:sessions[$session.id].SourceSettings = $settingsInfo
}

function GetSessionSettingsInfo($session) {
    $script:sessions[$session.id]
}

function GetExplicitModelSettingsFromSessionsByName([string] $modelName) {
    $script:sessions.Values | where-object {
        if ( $_.SourceSettings -and $_.SourceSettings.ModelSettings ) {
            $_.SourceSettings.ModelSettings.name -eq $modelName
        }
    } |
      select-object -ExpandProperty SourceSettings |
      select-object -ExpandProperty ModelSettings
}

function GetCompatibleModelSettingsFromSessions($session) {
    $script:sessions.Values | foreach {
        if ( $_.SourceSettings -and $_.SourceSettings.Model ) {
            if ( $_.SourceSettings.ModelSettings.IsCompatible($session.AiOptions) ) {
                break
            }
        }
    } |
      select-object -ExpandProperty SourceSettings |
      select-object -ExpandProperty ModelSettings
}

function SetCurrentSession($session) {
    if ( $script:sessions[$session.id] ) {
        $script:CurrentSession = $session
    } else {
        throw [InvalidOperationException]::new("The specified session id='$($session.id)' name='$($session.name)' was not found in the current list of valid sessions.")
    }
}

function GetCurrentSession([bool] $failIfNotFound = $false) {
    if ( $failIfNotFound -and (! $script:CurrentSession ) ) {
        throw "No current session exists -- use Connect-ChatSession to create a session"
    }

    $script:CurrentSession
}

function GetCurrentSessionId([bool] $failIfNotFound = $false) {
    $currentSession = GetCurrentSession $false

    if ( $currentSession ) {
        $currentSession.Id
    }
}

function GetChatSessions {
    if ( $script:sessions.Count -gt 0 ) {
        $script:sessions.Values.Session
    }
}

function GetTargetSession($userSpecifiedSession, [bool] $failIfNotFound = $false) {
    $targetSession = if ( $userSpecifiedSession ) {
        $userSpecifiedSession
    } else {
        GetCurrentSession
    }

    if ( $failIfNotFound -and (! $targetSession ) ) {
        throw "No current session exists -- use Connect-ChatSession to create a session"
    }

    $targetSession
}

function SendMessage($session, $prompt, $functionDefinition) {
    $sendBlock = GetSendBlock $session

    $targetPrompt = if ( ! $sendBlock ) {
        $prompt
    } else {
        $sendBlock.Invoke($prompt)
    }

    $response = if ( $functionDefinition ) {
        $session.GenerateFunctionResponse($functionDefinition, $targetPrompt)
    } else {
        $session.GenerateMessage(@($targetPrompt))
    }

    $receiveBlock = GetReceiveBlock $session

    if ( ! $receiveBlock ) {
        $response
    } else {
        $processedResponse = $receiveBlock.Invoke(@($response))
        $session.UpdateLastResponse($processedResponse)
        $processedResponse
    }
}

function SendConnectionTestMessage($session) {
    if ( ! $session.AccessValidated -and $session.IsRemote ) {
        write-progress "Connecting" -Percent 25
        $session.SendStandaloneMessage("Hello from $($session.id)", 'You are a friendly conversationalist.', $false) | out-null
        write-progress "Connecting" -Completed
    }
}

function GetSendBlock($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['SendBlock']
    }
}

function GetReceiveBlock($session) {
    if ( $session.CustomContext ) {
        $session.CustomContext['ReceiveBlock']
    }
}

function RegisterSessionCompleter([string] $command, [string] $parameterName) {
    $sessionNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $sessions = GetChatSessions | where $parameterName -ne $null | sort-object $parameterName
        $sessions.$parameterName | where { $_.ToString().StartsWith($wordToComplete, [System.StringComparison]::InvariantCultureIgnoreCase) }
    }

    Register-ArgumentCompleter -commandname $command -ParameterName $parameterName -ScriptBlock $sessionNameCompleter
}
