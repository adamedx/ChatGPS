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
