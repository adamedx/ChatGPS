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
# So it turns out that certain native libraries are a real pain, at least if you
# want to package libraries for multiple platforms (e.g. both x64 and arm64 on Windows)
# within the same software package like this one. The *onnx* packages used for local models
# include native libraries that are placed within platform specific directories invisible
# to the assembly loader, and thus they don't get loaded (and fail the loading of the
# parent assembly). To work around this, we check for their presence in the directory
# with all platform neutral assemblies when this script is executed at module load. If
# they are not present we copy the assemblies from the correct platform-specific directory
# into the platform neutral directory so that the assembly loader will find them when it
# attempst to load the parent assemblies.
#

set-strictmode -version 2
$erroractionpreference = 'stop'

function CurrentScriptDirectory {
    split-path -parent $psscriptroot
}

function GetCurrentPlatformIdentifier {
   $osFragment = [OperatingSystem]::IsLinux() ?
            "linux" : (
                [OperatingSystem]::IsMacOS() ?
                "osx" : (
                    [OperatingSystem]::IsWindows() ?
                    "win" : $null ) )

    $archFragment = if ( $osFragment ) {
        switch ( [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture ) {
            ([System.Runtime.InteropServices.Architecture]::X64) {
                "x64"
            }
            ([System.Runtime.InteropServices.Architecture]::Arm64) {
                "arm64"
            }
        }
    }

    if ( $archFragment ) {
        "$($osFragment)-$($archFragment)"
    }
}

function GetNativeLibrarySourceDirectory {
    $osFragment = [OperatingSystem]::IsLinux() ?
            "linux" : (
                [OperatingSystem]::IsMacOS() ?
                "osx" : (
                    [OperatingSystem]::IsWindows() ?
                    "win" : $null ) )

    $archFragment = if ( $osFragment ) {
        switch ( [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture ) {
            ([System.Runtime.InteropServices.Architecture]::X64) {
                "x64"
            }
            ([System.Runtime.InteropServices.Architecture]::Arm64) {
                "arm64"
            }
        }
    }

    $currentNativePlatformIdentifier = GetCurrentPlatformIdentifier

    if ( $currentNativePlatformIdentifier ) {
        $thisDirectory = CurrentScriptDirectory

        $targetPlatformSubdirectory = Join-Path 'lib/runtimes' $currentNativePlatformIdentifier
        $targetSubdirectory = Join-Path $targetPlatformSubdirectory native

        Join-Path $thisDirectory $targetSubdirectory
    }
}

function ConfigureNativeLibraries([bool] $skipCopy = $false, [string] $warningActionValue = 'Continue') {
    $nativeLibrarySource = GetNativeLibrarySourceDirectory
    $nativeLibraryDestination = join-path (CurrentScriptDirectory) lib

    if ( ! $nativeLibrarySource ) {
        write-warning "Unable to determine native library source directory -- native operations may not be supported for the current platform" -warningaction $warningActionValue
    } elseif ( ! ( test-path $nativeLibrarySource ) ) {
        write-warning "Native library source directory '$nativeLibrarySource' does not exist -- native operations will not be supported" -warningaction $warningActionValue
    } else {
        if ( test-path $nativeLibraryDestination ) {
            $nativeLibraries = if ( [OperatingSystem]::IsLinux() ) {
            } elseif ( [OperatingSystem]::IsLinux() ) {
                @(
                    'libonnxruntime_providers_shared.so'
                    'libonnxruntime-genai.so'
                    'libonnxruntime.so')
            } elseif ( [OperatingSystem]::IsMacOS() ) {
                @(
                    'libonnxruntime-genai.dylib'
                    'libonnxruntime.dylib')
            } elseif ( [OperatingSystem]::IsWindows() ) {
                @(
                    'onnxruntime_providers_shared.dll'
                    'onnxruntime-genai.dll'
                    'onnxruntime.dll')
            }

            foreach ( $library in $nativeLibraries ) {
                $sourceLibraryPath = join-path $nativeLibrarySource $library
                $targetLibraryPath = join-path $nativeLibraryDestination $library

                if ( ! ( test-path $targetLibraryPath ) ) {
                    if ( test-path $sourceLibraryPath ) {
                        if ( ! $skipCopy ) {
                            copy-item $sourceLibraryPath $targetLibraryPath
                        } else {
                            if ( ! ( test-path $sourceLibraryPath ) ) {
                                throw 'Native library not not found'
                            }
                        }
                    } else {
                        write-warning "Unable to find native library '$sourceLibraryPath'; native operations may not be supported for the current platform" -warningaction $warningActionValue
                    }
                }
            }
        } else {
            write-warning "Cannot find module library dependency directory '$nativeLibraryDestination'; the module may not function." -warningaction $warningActionValue
        }
    }
}

$skipVariable = get-variable -scope global __ChatGPSSkipNative -erroraction ignore

if ( ! $skipVariable -or ! ( $skipVariable.value -eq $true ) ) {
    write-verbose "Starting native library configuration in runtime mode."
    ConfigureNativeLibraries -warningactionvalue SilentlyContinue
} else {
    write-verbose "Skipping library configuration because this is not runtime mode."
    ConfigureNativeLibraries $true -warningactionvalue SilentlyContinue
}


