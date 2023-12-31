#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

enum ReplStatus
{
    NaturalLanguage
    Native
    Exited
}

class ReplState
{
    ReplState([PSCustomObject] $Connection, [ReplStatus] $Status = [ReplStatus]::Native) {
        $this.status = $Status
        $this.stateVariables = @{
            Connection = $Connection
        }
    }

    [void] Update([HashTable] $UpdatedVariables) {
        $newStatus = if ( $UpdatedVariables ) {
            $UpdatedVariables['Status']
        }

        if ( $newStatus ) {
            $this.status = $newStatus
        }
    }

    [HashTable] GetState() {
        $state = $this.stateVariables.Clone()
        $state['Status'] = $this.status

        return $state
    }

    hidden [HashTable] $stateVariables = $null
    hidden [ReplStatus] $status
}
