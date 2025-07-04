#
# Copyright (c) Adam Edwards
#
# All rights reserved.

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
