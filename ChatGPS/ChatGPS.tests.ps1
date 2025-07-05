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
    Describe 'The ChatGPS PowerShell module' {
        BeforeAll {
            $module = Get-Module ChatGPS
            $moduleBase = $module | select -ExpandProperty modulebase
            $moduleBaseLength = $moduleBase.Length

            $moduleManifestRelativePaths = $module.FileList | foreach {
                $_.substring($moduleBaseLength + 1, $_.length - $moduleBaseLength - 1)
            }

            $moduleFileSystemRelativePaths = get-childitem $moduleBase -r *.ps1 | foreach {
                $_.fullname.substring($moduleBaseLength + 1, $_.fullname.length - $moduleBaseLength - 1)
            }
        }

        Context 'When inspecting the ChatGPS module manifest' {
            It 'Should have an entry in the FileList array for each .ps1 file located recursively under the module base directory' {
                $moduleFileSystemRelativePaths | foreach {
                    $moduleManifestRelativePaths | Should -Contain $_
                }
            }
        }
    }
}
