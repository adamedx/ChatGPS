#
# Copyright (c), Adam Edwards
#
# All rights reserved.
#

set-strictmode -version 2
$erroractionpreference = 'stop'


$jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
$jsonOptions.IncludeFields = $true


$functionDefinitions = @{
    PowerShell = @{
        Definition = "Show the PowerShell code to accomplish the objective specified by {{`$input}} on this computer. Your response should include ONLY the code, no additional commentary, and there should be no markdown formatting for instance. If you cannot generate the code, then you must instead generate PowerShell code that throws an exception with a string message that states that you could not generate the code."
        Parameters = @('input')
    }
}

function AddFunction([string] $functionName, [string] $functionDefinition, [string[]] $parameters) {
    $definition = NewFunctionDefinition $functionDefinition $parameters
    AddFunctionDefinition $functionName $definition
}

function AddFunctionDefinition([string] $functionName, [HashTable] $functionDefinition) {
    $functionDefinitions[$functionName] = $functionDefinition
}

function NewFunctionDefinition([string] $functionDefinition, [string[]] $parameters) {
    @{
        Definition = $functionDefinition
        Parameters = $parameters
    }
}

function Start-ProxyRepl {
    [cmdletbinding(positionalbinding=$false)]
    param(
        [parameter(parametersetname='repl')]
        [switch] $Repl,

        [string] $ProxyExecutablePath = 'dotnet',

        [string[]] $ProxyExecutableParameters,

        [string] $AssemblyPath = "$psscriptroot/../bin/debug/net7.0",

        [string] $ConfigPath = "$psscriptroot/../../azureopenai.config",

        [switch] $NoLoadAssemblies,

        [int32] $IdleTimeout = 120000,

        [string] $LogFile,

        [validateset('Default', 'None', 'Error', 'Debug', 'DebugVerbose')]
        [string] $LogLevel,

        [string] $SystemPrompt = 'You are an assistant who provides support and encouragement for people to understand mathematics, science, and technology topics.',

        [switch] $Reset
    )

    $currentCommand = $null

    if ( ! $NoLoadAssemblies.IsPresent ) {
        [System.Reflection.Assembly]::LoadFrom("$AssemblyPath\Microsoft.SemanticKernel.Abstractions.dll") | out-null
        [System.Reflection.Assembly]::LoadFrom("$AssemblyPath\Microsoft.SemanticKernel.dll") | out-null
        [System.Reflection.Assembly]::LoadFrom("$AssemblyPath\AIService.dll") | out-null
    }

    if ( $Reset.IsPresent -or (get-variable __TEST_AIPROXY_SESSION -erroraction ignore ) -eq $null ) {
        $script:__TEST_AIPROXY_SESSION_ID = $null
        $newChat = [microsoft.semantickernel.chatcompletion.chathistory]::new()
        $newChat.AddMessage('System', $SystemPrompt)

        $script:__SESSION_HISTORY = $newChat
    }

    function CreateConnectionRequest($connectionOptionsJson) {
        $aioptions = if ( $connectionOptionsJson ) {
            [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.AiOptions]($connectionOptionsJson, $jsonOptions)
        }
        $newConnection = [Modulus.ChatGPS.Models.Proxy.CreateConnectionRequest]::new()
        $newConnection.ServiceId = ([ServiceBuilder+ServiceId]::AzureOpenAi)
        $newConnection.ConnectionOptions = $aioptions

        $commandArguments = [System.Text.Json.JsonSerializer]::Serialize($newConnection, $newConnection.GetType(), $jsonOptions)

        $commandArguments
    }

    function ProcessOutput($decodedOutput) {
        if ( $decodedOutput ) {
            $response = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.ProxyResponse]($decodedOutput, $jsonOptions)

            if ( $response.Status -ne ([Modulus.ChatGPS.Models.Proxy.ProxyResponse+ResponseStatus]::Success) ) {
                write-error "Command '$commandName' failed with status $($response.Status.ToString())" -erroraction continue

                if ( $response.Exceptions -ne $null -and $response.Exceptions.Length -gt 0 ) {
                    $exception = $response.Exceptions[0]
                    $exception | write-error -erroraction continue;
                    throw $response.Exceptions[0]
                }
            } else {
                switch ( $commandName ) {
                    '.connect' {
                        $connectionContent = $response -ne $null ? $response.Content : $null
                        if ( $connectionContent ) {
                            $connectionResponse = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.CreateConnectionResponse]($connectionContent, $jsonOptions)
                            $script:__TEST_AIPROXY_SESSION_ID = $connectionResponse.ConnectionId
                        }

                        break
                    }
                    '.sendchat' {
                        $chatContent = $response -ne $null ? $response.Content : $null
                        if ( $chatContent ) {
                            $chatResponse = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.SendChatResponse]($chatContent, $jsonOptions)
                            $chatMessage = $chatResponse.ChatResponse.Content
                            $script:__SESSION_HISTORY.AddMessage('Assistant', $chatMessage)
                            $chatMessage
                        }
                        break
                    }
                    '.invoke' {
                        $functionContent = $response -ne $null ? $response.Content : $null
                        if ( $functionContent ) {
                            $functionResponse = [System.Text.Json.JsonSerializer]::Deserialize[Modulus.ChatGPS.Models.Proxy.InvokeFunctionResponse]($functionContent, $jsonOptions)
                            $chatMessage = $functionResponse.Output.Result
                            $script:__SESSION_HISTORY.AddMessage('Assistant', $chatMessage)
                            $chatMessage
                        }
                        break
                    }
                    default {
                        break
                    }
                }
            }
        }
    }

    function CreateSendChatRequest($message) {
        $chatRequest = [Modulus.ChatGPS.Models.Proxy.SendChatRequest]::new()
        $script:__SESSION_HISTORY.AddMessage('User', $message)
        $chatRequest.History = $script:__SESSION_HISTORY

        [System.Text.Json.JsonSerializer]::Serialize($chatRequest, $chatRequest.GetType(), $jsonOptions)
    }

    function CreateInvokeFunctionRequest([string] $functionName, $functionParameters) {
        $functionDefinition = $functionDefinitions[$functionName]

        if ( ! $functionDefinition ) {
            throw "There is no defined function named '$functionName'"
        }

        $boundParameters = @{}

        $paramList = if ( $functionDefinition.Parameters.Length -gt 0 ) {
            $functionDefinition.Parameters | Join-String -outputprefix '$' -Separator ',$'
        } else {
            ""
        }

        $paramScriptBlock = [ScriptBlock]::Create(
@"
function __Get-Params {param($paramList)
    `$result=[System.Collections.Generic.Dictionary[string,object]]::new()
    `$PSBoundParameters.keys | foreach {
        `$result.Add( `$_, `$PSBoundParameters[`$_])
    }
    `$result
}
__Get-Params $functionParameters
"@
        )

        $boundParameters = Invoke-Command -ScriptBlock $paramScriptBlock

        write-verbose "Calling function '$functionName'"

        foreach ( $parameter in $boundParameters.keys ) {
            write-verbose "`t$parameter`t`t = `t$($boundParameters[$parameter])"
        }

        $functionRequest = [Modulus.ChatGPS.Models.Proxy.InvokeFunctionRequest]::new($functionDefinition.Definition, $boundParameters)
        $script:__SESSION_HISTORY.AddMessage('User', $functionParameters)

        [System.Text.Json.JsonSerializer]::Serialize($functionRequest, $functionRequest.GetType(), $jsonOptions)
    }

    function ProcessLocalCommand ($localCommand, $arguments) {
        switch ( $localCommand ) {
            '.showconnection' {
                $script:__TEST_AIPROXY_SESSION_ID
                break
            }
            '.showfunction' {
                foreach ( $functionName in $script:functionDefinitions.keys ) {
                    $definition = $script:functionDefinitions[$functionName]
                    [PSCustomObject] @{
                        Name = $functionName
                        Parameters = $definition.Parameters
                        Definition = $definition.Definition
                    }
                }
                break
            }
            '.function' {
                $functionScriptBlock = [ScriptBlock]::Create(
@"
function __Get-Function {param(
                             [parameter(mandatory=`$true)] [string] `$functionName,
                             [string[]] `$functionParameters = @(),
                             [string] `$functionDefinition = ""
                         )
    @{
        Name = `$functionName
        Parameters = `$functionParameters
        Definition = `$functionDefinition
    }
}
__Get-Function $arguments
"@
                )
                $newFunction = Invoke-Command -ScriptBlock $functionScriptBlock
                AddFunction $newFunction.Name $newFunction.Definition $newFunction.Parameters
                break
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

    $logLevelArgument = if ( $LogLevel ) {
        "--debuglevel $LogLevel"
    } else {
        ""
    }

    $logFileArgument = if ( $LogFile ) {
        "--logfile '$LogFile'"
    } else {
        ""
    }

    $dotNetArguments = "run --debug $logLevelArgument $logFileArgument --timeout $IdleTimeout --project $psscriptroot\..\AIProxy.csproj --no-build"

    $processArguments = "-noprofile -command ""& '$dotnetlocation' $dotNetArguments"""

    $process = [System.Diagnostics.Process]::new()

    $process.StartInfo.FileName = 'pwsh'

    $process.StartInfo.Arguments = $processArguments
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardInput = $true
    $process.StartInfo.UseShellExecute = $false

    Register-ObjectEvent -Action {param($i, $e) write-verbose 'EXITING' } -InputObject $process -EventName 'Exited' | out-null

    write-verbose "Starting process with process with arguments '$processArguments'"

    $process.start() | out-null

    write-verbose "Started process successfully with PID $$(process.Id)"

    $tries = 0
    $commandName = $null

    while ( ! $process.hasexited ) {
        write-debug READINPUT
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
                        if ( $script:__TEST_AIPROXY_SESSION_ID -eq $null ) {
                            throw "Cannot send chat message because no connection id was specified"
                        }

                        $proxyCommandArguments = CreateSendChatRequest $commandArguments
                        'sendchat'
                        break
                    }
                    '.invoke' {
                        if ( $script:__TEST_AIPROXY_SESSION_ID -eq $null ) {
                            throw "Cannot invoke function because no connection id was specified"
                        }

                        $splitArguments = $commandArguments -split ' '

                        $functionName = $splitArguments[0]

                        $functionParameters = if ( $splitArguments.Length -gt 1 ) {
                            $commandArguments.SubString($functionName.Length, $commandArguments.Length - $functionName.Length).Trim()
                        }

                        $proxyCommandArguments = CreateInvokeFunctionRequest $functionName $functionParameters
                        'invokefunction'
                    }
                    '.showconnection' {
                        'localcommand'
                        break
                    }
                    '.showfunction' {
                        'localcommand'
                        break
                    }
                    '.function' {
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

        $targetConnectionId = $script:__TEST_AIPROXY_SESSION_ID -ne $null ? $script:__TEST_AIPROXY_SESSION_ID : [Guid]::Empty

        $request.CommandName = $proxyCommand
        $request.RequestId = [Guid]::NewGuid()
        $request.Content = $proxyCommandArguments

        $request.TargetConnectionId = $targetConnectionId

        $serializedRequest = [System.Text.Json.JsonSerializer]::Serialize($request, $request.GetType(), $jsonOptions)

        write-verbose "Sending: $serializedRequest"

        $unencodedRequestBytes = [System.Text.Encoding]::UTF8.GetBytes($serializedRequest)
        $commandRequest = [System.Convert]::ToBase64String($unencodedRequestBytes)

        $failed = $false

        write-verbose $commandRequest

        write-progress "Sending request" -PercentComplete 30

        try {
            $currentCommand = $commandName
            $process.standardInput.WriteLine($commandRequest)
        } catch {
            write-verbose "Failed to write output"
            $_ | write-verbose
            $failed = $true
        }

        write-verbose "Request sent"

        # Read until you get a failure (quit) or then find a line not starting with '.'
        # The '.' only exists for debug output that is sent to standard output, so it is not
        # part of the proxy's output stream to standard output.
        # If you find that line, process it, then stop reading lines

        $output = $null

        while ( ! $process.hasexited -and ! $failed ) {
            try {
                write-progress "Waiting for response" -PercentComplete 80
                $currentLine = $process.StandardOutput.Readline()
                if ( $currentLine ) { write-verbose $currentLine }
                if ( ! $currentLine -or $currentLine[0] -eq '.' ) {
                    write-debug SKIPPING
                    continue
                }
                write-debug KEEPING
                $output = $currentLine
                break
            } catch {
                $_ | write-error -erroraction continue
                $failed = $true
                break
            }
        }

        if ( $failed ) {
            write-progress "Failed" -completed
            continue;
        }

        $decodedOutput = if ( $output ) {
            if ( $output[0] -eq '{' ) {
                $output
            } else {
                $decodedBytes = [System.Convert]::FromBase64String($output)
                [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            }
        } else {
            write-debug reademptyline
            break
        }

        write-debug RECEIVEDOUTPUT

        write-progress "Processing response" -percentcomplete 98

        write-verbose "Received: $decodedOutput"

        try {
            ProcessOutput $decodedOutput
        } catch [Modulus.ChatGPS.Models.SerializableException] {
            $_ | write-error -erroraction continue
        }

        write-progress "Finished processing request" -Completed
    }

    if ( $process.hasexited ) {
        write-verbose 'Successfully detected exit'
    }
}
