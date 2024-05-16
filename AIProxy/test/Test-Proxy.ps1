#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

[cmdletbinding(positionalbinding=$false)]
param(
    [parameter(parametersetname='repl')]
    [switch] $Repl,

    [string] $ProxyExecutablePath = 'dotnet',

    [string[]] $ProxyExecutableParameters,

    [string] $AssemblyPath = "$psscriptroot/../bin/debug/net7.0",

    [string] $ConfigPath = "$psscriptroot/../../azureopenai.config",

    [switch] $NoLoadAssemblies,

    [string] $SystemPrompt = 'You are an assistant who provides support and encouragement for people to understand mathematics, science, and technology topics.',

    [switch] $Reset
)
set-strictmode -version 2
$erroractionpreference = 'stop'
$currentCommand = $null

if ( ! $NoLoadAssemblies.IsPresent ) {
    [System.Reflection.Assembly]::LoadFrom("$AssemblyPath\ChatGPSLib.dll") | out-null
    [System.Reflection.Assembly]::LoadFrom("$AssemblyPath\Microsoft.SemanticKernel.Abstractions.dll") | out-null
}

if ( $Reset.IsPresent -or (get-variable __TEST_AIPROXY_SESSION -erroraction ignore ) -eq $null ) {
    $script:__TEST_AIPROXY_SESSION_ID = $null
    $newChat = [microsoft.semantickernel.chatcompletion.chathistory]::new()
    $newChat.AddMessage('System', $SystemPrompt)

    $script:__SESSION_HISTORY = $newChat
}

function CreateConnectionRequest($connectionOptionsJson) {
    $aioptions = if ( $connectionOptionsJson ) {
        [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.AiOptions]($connectionOptionsJson)
    }
    $newConnection = [Modulus.ChatGPS.Models.Proxy.CreateConnectionRequest]::new()
    $newConnection.ServiceId = ([ServiceBuilder+ServiceId]::AzureOpenAi)
    $newConnection.ConnectionOptions = $aioptions

    $commandArguments = [System.Text.Json.JsonSerializer]::Serialize($newConnection, $newConnection.GetType())

    $commandArguments
}

function ProcessOutput($decodedOutput) {
    if ( $decodedOutput ) {
        $response = [System.Text.Json.JsonSerializer]::Deserialize[ProxyResponse]($decodedOutput)

        if ( $response.Status -ne ([ProxyResponse+ResponseStatus]::Success) ) {
            write-error "Command '$commandName' failed with status $($response.Status.ToString())" -erroraction continue

            foreach ( $exception in $response.exceptions ) {
                $exception | write-error -erroraction continue
            }
        } else {
            switch ( $commandName ) {
                '.connect' {
                    $connectionContent = $response -ne $null ? $response.Content : $null
                    if ( $connectionContent ) {
                        $connectionResponse = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.CreateConnectionResponse]($connectionContent)
                        $script:__TEST_AIPROXY_SESSION_ID = $connectionResponse.ConnectionId
                    }

                    break
                }
                '.sendchat' {
                    $chatContent = $response -ne $null ? $response.Content : $null
                    if ( $chatContent ) {
                        $chatResponse = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.SendChatResponse]($chatContent)
                        $chatMessage = $chatResponse.ChatResponse
                        $script:__SESSION_HISTORY.AddMessage('Assistant', $chatMessage)
                        $chatMessage
                    }
                }
                default {
                    break
                }
            }
        }
    }
}

function CreateSendChatRequest($message, $connectionId) {
    $targetConnectionId = $connectionId -eq $null ? $script:__TEST_AIPROXY_SESSION_ID : $connectionId

    if ( $targetConnectionId -eq $null ) {
        throw "Cannot send chat message because no connection id was specified"
    }

    $requestId = [Guid]::NewGuid()
    $chatRequest = [Modulus.ChatGPS.Models.Proxy.SendChatRequest]::new($requestId)
    $chatRequest.ConnectionId = $targetConnectionId
    $script:__SESSION_HISTORY.AddMessage('User', $message)
    $chatRequest.History = $script:__SESSION_HISTORY

    $options = [System.Text.Json.JsonSerializerOptions]::new()
    $options.IncludeFields = $true
    [System.Text.Json.JsonSerializer]::Serialize($chatRequest, $chatRequest.GetType(), $options)
}

function ProcessLocalCommand ($localCommand, $arguments) {
    switch ( $localCommand ) {
        '.showconnection' {
            $script:__TEST_AIPROXY_SESSION_ID
        }
        default {
            break
        }
    }
}

$aiconfig = if ( $ConfigPath ) {
    get-content $ConfigPath | out-string
}

$dotnetlocation = get-command $ProxyExecutablePath | select -expandproperty source

# $dotNetArguments = "-noprofile -command ""& '$dotnetlocation' run --serviceid AzureOpenAi --config stuff --debug --timeout 60000 --no-encodedarguments --project $psscriptroot\..\AIProxy.csproj --no-build"""

$dotNetArguments = "run --serviceid AzureOpenAi --debug --timeout 60000 --project $psscriptroot\..\AIProxy.csproj --no-build"

$processArguments = "-noprofile -command ""& '$dotnetlocation' $dotNetArguments"""
# $processArguments = $dotNetArguments

$process = [System.Diagnostics.Process]::new()

$process.StartInfo.FileName = 'pwsh'

$process.StartInfo.Arguments = $processArguments
# $process.StartInfo.RedirectStandardError = $true
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardInput = $true
$process.StartInfo.UseShellExecute = $false
# $process.StartInfo.StandardOutputEncoding = ([System.Text.Encoding]::Utf8)

Register-ObjectEvent -Action {param($i, $e) write-host 'EXITING' } -InputObject $process -EventName 'Exited' | out-null

$processArguments

$process.start() | out-null

$process.Id

$tries = 0
$commandName = $null

while ( ! $process.hasexited ) {
    write-verbose READINPUT
    $proxyCommand = read-host "PX> "
    $invalidCommand = $false

    $commandNameDelimiterIndex = $proxyCommand.IndexOf(' ')

    $commandNameEnd = $commandNameDelimiterIndex -ne -1 ? $commandNameDelimiterIndex : $proxyCommand.Length

    $commandName = $proxyCommand.substring(0, $commandNameEnd).Trim()

    $commandArguments = if ( $commandName.Length -lt ( $proxyCommand.Length - 1 ) ) {
        $proxyCommand.Substring($commandName.Length + 1, $proxyCommand.Length - $commandNameEnd - 1).Trim()
    }

    $proxyCommandArguments = $null

    $exitRequested = $false

    $proxyCommand = try {
        if ( $commandName.StartsWith('.') ) {
            switch ( $commandName ) {
                '.exit' {
                    $exitRequested = $true
                    'exit'
                    break
                }

                '.command' {
                    $proxyCommand.Substring($commandName.Length + 1, $proxyCommand.Length - $commandNameEnd).Trim()
                    break
                }

                '.connect' {
                    $configJson = if ( $aiconfig ) {
                        $aiconfig
                    } else {
                        $proxyCommand.Substring($commandNameEnd + 1, $proxyCommand.Length - $commandNameEnd).Trim()
                    }

                    $proxyCommandArguments = CreateConnectionRequest $configJson
                    'createconnection'
                    break
                }
                '.sendchat' {
                    $proxyCommandArguments = CreateSendChatRequest $commandArguments
                    'sendchat'
                    break
                }
                '.showconnection' {
                    'localcommand'
                    break
                }

                default {
                    $invalidCommand = $true
                    break
                }
            }
        } else {
            $proxyCommandArguments = CreateSendChatRequest $proxyCommand.Trim()
            $commandName = '.sendchat'
            'sendchat'
        }
    } catch {
        write-error $_ -erroraction continue
    }

    if ( $exitRequested ) {
        break
    }

    if ( $invalidCommand )  {
        write-error "Command '$commandName' is not a valid command" -erroraction continue
        continue
    }

    if ( ! $proxyCommand ) {
        continue
    }

    if ( $proxyCommand -eq 'localcommand' ) {
        ProcessLocalCommand $commandName $commandArguments | write-host
        continue
    }

    $request = [Modulus.ChatGPS.Models.Proxy.ProxyRequest]::new()

    $request.CommandName = $proxyCommand
    $request.RequestId = [Guid]::NewGuid()
    $request.Content = $proxyCommandArguments

    $serializedRequest = [System.Text.Json.JsonSerializer]::Serialize($request, $request.GetType())

    $unencodedRequestBytes = [System.Text.Encoding]::UTF8.GetBytes($serializedRequest)
    $commandRequest = [System.Convert]::ToBase64String($unencodedRequestBytes)

    $failed = $false

    write-verbose $commandRequest

    try {
        $currentCommand = $commandName
        $process.standardInput.WriteLine($commandRequest)
    } catch {
        $failed = $true
    }

    # Read until you get a failure (quit) or then find a line not starting with '.'
    # The '.' only exists for debug output that is sent to standard output, so it is not
    # part of the proxy's output stream to standard output.
    # If you find that line, process it, then stop reading lines

    $output = $null

    while ( ! $process.hasexited -and ! $failed ) {
        try {
            $currentLine = $process.StandardOutput.Readline()
            write-verbose $currentLine
            if ( ! $currentLine -or $currentLine[0] -eq '.' ) {
                write-verbose SKIPPING
                continue
            }
            write-verbose KEEPING
            $output = $currentLine
            break
        } catch {
            $_ | write-error -erroraction continue
            $failed = $true
            break
        }
    }

    $decodedOutput = if ( $output ) {
        if ( $output[0] -eq '{' ) {
            $output
        } else {
            $decodedBytes = [System.Convert]::FromBase64String($output)
            [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        }
    } else {
        write-verbose reademptyline
        break
    }

    write-verbose RECEIVEDOUTPUT

    ProcessOutput $decodedOutput

    start-sleep 1
}

if ( $process.hasexited ) {
    'success'
}
