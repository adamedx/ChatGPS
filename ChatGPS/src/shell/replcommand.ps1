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

#
$HistoryTypeName = 'Modulus.ChatGPS.PowerShell.ChatHistory'

$ReplCommands = @{
    Exit = {param([HashTable] $ReplState) ReplCommandExit}
    History = {param([HashTable] $ReplState) ReplCommandHistory @args}
    Last = {param([HashTable] $ReplState) ReplCommandHistory 1 1}
    Help = {param([HashTable] $ReplState) ReplCommandHelp}
    ClearHistory = {param([HashTable] $ReplState) ReplCommandClearHistory}
    ShowConnection = {param([HashTable] $ReplState) ReplCommandShowConnection}
}

function InvokeReplCommand {
    [cmdletbinding()]
    param(
        [string] $InputText,
        [HashTable] $ReplState,
        [PSModuleInfo] $targetModule = $null
    )

    $trimmedText = $InputText -ne '?' ? $InputText.Trim() : '.help'

    $commandName = $null

    $argumentStart = $trimmedText.IndexOf(' ')

    $commandBlock = if ( $trimmedText[0] -eq '.' ) {
        $commandLength = $argumentStart -gt 0 ? $argumentStart - 1: $trimmedText.Length - 1
        $commandName = $trimmedText.SubString(1, $commandLength)

        $block = $script:ReplCommands[$commandName]

        if ( ! $block ) {
            write-error -erroraction continue "The command '$commandName' is not a valid command."
            $block = $script:ReplCommands['help']
        }

        $block
    }

    if ( $commandBlock ) {
        $argumentString = if ( $commandName.Length -lt ( $trimmedText.Length + 1 ) ) {
            $trimmedText.SubString($commandName.Length + 1, $trimmedText.Length - $commandName.Length - 1)
        }

        $targetBlock = if ($argumentString) {
            $argumentBlock = [ScriptBlock]::Create($argumentString)
            if ( $targetModule ) {
                $targetModule.NewBoundScriptBlock($argumentBlock)
            } else {
                $argumentBlock
            }
        }

        $commandArguments = @($Replstate)

        if ( $targetBlock ) {
            $commandArguments += $targetBlock.InvokeReturnAsIs()
        }

        Invoke-Command -ScriptBlock $commandBlock -ArgumentList $commandArguments
    }
}

function ToCommandOutput {
    param(
        $Result,

        [HashTable] $NewReplState
    )
    [PSCustomObject] @{
        Result = $Result
        UpdatedReplState = $NewReplState
    }
}

function ReplCommandExit {
    ToCommandOutput $null @{Status = 'Exit'}
}

function ReplCommandHelp {
    $result = foreach ( $commandName in $ReplCommands.Keys ) {
        "." + $commandName.ToLower()
    }

    ToCommandOutput (
        & {
            "`nShell commands must start with '.'; valid commands are:`n"
            ( $result | sort-object )
        }
    )
}


function ReplCommandHistory( $LatestCount = -1, $Length = -1) {
    $lastCount = $LatestCount -ge 0 ? $LatestCount : $ReplState.Connection.History.Count

    $resultLength = $Length -ge 0 ? $Length : $lastCount

    $index = 0
    $emittedCount = 0

    $result = $ReplState.Connection.History |
      select -last $lastCount |
      select -first $resultLength |
      foreach {
          if ( $index++ -eq 0 ) {
              [PSCustomObject] @{History=''} | format-list
          }

          $emittedItem = if ( $_.Role -ne 'system' ) {
              $received = if ( $_.Timestamp ) {
                  $_.Timestamp
              } else {
                  '------'
              }

              $responseParams = @{Role=$_.Role}

              if ( $received ) {
                  $responseParams['Received'] = $received
              }
              $historyItem = $_.Content | ToResponse @responseParams
              SetObjectType $historyItem $script:HistoryTypeName
              if ( $emittedCount -eq 0 ) {
                  $historyItem
              } else {
                  $historyItem
              }
              $emittedCount++
          }
          $emittedItem

          if ( $index -eq $resultLength ) {
              $footer = [PSCustomObject] @{Content = ''}
              SetObjectType $footer $script:HistoryTypeName
              $footer | format-table -hidetableheaders
          }
      }

    ToCommandOutput $result
}

function ReplCommandClearHistory {
    Clear-ChatHistory -Session $ReplState.Connection
    ToCommandOutput "Chat history cleared at $([DateTime]::now)."
}

function ReplCommandShowConnection {
    ToCommandOutput $ReplState.Connection
}
