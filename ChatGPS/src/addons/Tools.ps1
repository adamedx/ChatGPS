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

function InstallLibs([bool] $forcePrivateDotNet) {

    # WORKAROUND: Wow. So we need to install some libraries, some dll's that we
    # can't package with the module without blowing it up to 100 GB... compressed
    # in the module repository. You'd *think* we could just use PowerShell's
    # Install-Package command to do this, right? You are wrong! For some reason,
    # the packages we need to install "cannot be found" even with AllowPrerelease set.
    # But strangely a wildcard search with Find-Module finds it (but not an exact
    # search). Many workarounds were explored, and in the end, we just decided to
    # do the ony thing known to work: use build tools since this is actually how
    # we originally generated this prior to caring about module size. So... step 1
    # is to install the build tools in an isolated location if they aren't present
    # some how already (e.g. user has installed them for their own use cases). Cuz
    # yeah, we're going to do a build. PowerShell truly be trippin.
    Write-Progress -Id 1 -Activity 'Installing .net tools'

    $dotNetToolPath = GetDotNet $forcePrivateDotNet

    write-verbose "Using dotnet executable '$dotNetToolPath' to install libraries."

    $installDirectory = GetInstallDirectory

    # WORKAROUND: So, it turns out Test-ModuleManifest won't let you just list
    # any file types in the module manifest, only certain file types. And text,
    # xml, cs files, many others aren't in the list. :(. Oh, and if you don't list the files
    # they won't get published by Publish-Module. So as a workaround, the two files
    # we need here, a .cs file and a .csproj file, are published as .ps1 files
    # (at least those are allowed :)), and we then rename the to the correct types
    # when we copy them. Wow.
    copy-item $psscriptroot/addons.ps1 "$installDirectory/addons.csproj"
    copy-item $psscriptroot/Program.ps1 "$installDirectory/Program.cs"

    $projectFilePath = (get-item $installDirectory/addons.csproj).fullname

    $buildCommand = "'$dotNetToolPath' build $projectFilePath --configuration release"

    $buildCommand | write-debug

    Write-Progress -Id 1 -Activity 'Installing libraries' -percentcomplete 15

    # WORKAROUND: We need to run the build, but in local testing, we have a global.json.
    # If you are a .net developer you know this forces a certain SDK version on you, which
    # will cause errors when the dotnet tool detects a mismatch between it and global.json.
    # Yes, I know this is a developer setup that is testing directly from source rather than
    # published module, but it's a huge efficiency win for contributors to be able to do this.
    # So to work around global.json, we change to a different directory becauase apparently
    # you can't override global.json on the command line.
    $output = try {
        pushd /
        # Run the build!
        Invoke-Expression "& $buildCommand"
    } finally {
        popd
    }

    $output | write-debug

    # Now that the build is done, it has downloaded the libraries and placed them in a
    # temporary directory of our choosing.
    $tempLibrarySource = GetTempLibrarySourceDirectory $installDirectory

    write-verbose "copy-item -r '$tempLibrarySource/*' (join-path $psscriptroot ../../lib) -erroraction ignore"

    # Copy the libraries from the temporary directory into the actual module where they can
    # be used.
    Write-Progress -id 1 -Activity 'Copying libraries to ChatGPS' -percentcomplete 90
    copy-item -r "$tempLibrarySource/*" (join-path $psscriptroot ../../lib) -erroraction ignore

    # This last step moves some additional files in the module to the correct location. This
    # was required even when we pre-packaged the libraries.
    Write-Progress -id 1 -Activity 'Configuring ChatGPS to use libraries' -percentcomplete 100
    ConfigureNativeLibraries -WarningActionValue Stop

    Write-Progress -Id 1 -Activity 'Installation compete' -Completed

    # Cleaning up is not strictly necessary, but it does free up some unneeded space
    # and also removes state that might impact future execution of this script, say
    # if errors were encountered the first time the script was run (network failure?).
    # Starting off clean with less state means greater odds of success on re-run.
    remove-item -r -force $tempLibrarySource -erroraction ignore
    remove-item -r -force "$installDirectory/bin" -erroraction ignore
    remove-item -r -force "$installDirectory/obj" -erroraction ignore

    $dotNetToolPath
}

function GetInstallDirectory {
    $targetInstallDirectory = join-path $psscriptroot ../../.install

    if ( ! ( test-path $targetInstallDirectory ) ) {
        mkdir $targetInstallDirectory | out-null
    }

    (get-item $targetInstallDirectory).FullName
}

function GetTempLibrarySourceDirectory {
    param(
        [parameter(mandatory=$true)]
        [string] $installDirectory
    )
    # This must match what is in the csproj file
    join-path $installDirectory tmplib
}

function GetDotNet([bool] $forcePrivate) {

    $isWindowsOS = $PSVersionTable.Platform -eq 'Win32NT'

    $installDirectory = GetInstallDirectory

    $dotnetDirectory = join-path $installDirectory dotnet

    $targetExe = if ( $isWindowsOS ) {
        'dotnet.exe'
    } else {
        'dotnet'
    }

    $privateDotNetPath = join-path $dotnetDirectory $targetExe

    $dotNetToolCommand = get-command dotnet -erroraction ignore

    $existingDotnetToolPath = if ( $dotNetToolCommand -and ! $forcePrivate ) {
        $dotNetToolCommand.Path
    } else {
        write-verbose "Required 'dotnet' tool not detected, looking under install directory $dotnetDirectory and retrying..."
        if ( test-path $privateDotNetPath ) {
            (Get-Item $privateDotNetPath).FullName
        }
    }

    # This minimum version thing is likely not needed in practice since
    # any version of the .net tool from the past 5 years will probably suffice for
    # what we need it to do (download dependencies during a build). But just to be safe...
    $hasValidVersion = $false
    $minimumVersionString = '8.0.3'

    if ( $existingDotNetToolPath ) {
        write-verbose "Found dotnet tool at '$existingDotNetToolPath', will check version"
        $minimumVersion = $minimumVersionString -split '\.'

        # WORKAROUND: Using the global.json workaround mentioned elsewhere in this file.
        $dotNetVersionString = try {
            pushd /
            ( & $existingDotNetToolPath --version )
        } finally {
            popd
        }

        $dotNetVersion = $dotNetVersionString -split '\.'
        write-verbose "Looking for minimum version '$minimumVersionString'"
        write-verbose "Found dotnet version '$dotNetVersionString'"

        if ( ([int]$dotNetVersion[0]) -ge [int]$minimumVersion[0] -and
             ([int]$dotNetVersion[1]) -ge [int]$minimumVersion[1] -and
             ([int]$dotNetVersion[2]) -ge [int]$minimumVersion[2] ) {
                 write-verbose 'Detected version meets minimum version requirement, no download necessary.'
                 $hasValidVersion = $true
             } else {
                 write-verbose 'Detected version does not meet minimum version requirement, download will be required.'
             }
    }

    if ( ! $hasValidVersion ) {
        $destinationPath = $installDirectory

        write-verbose "Executable not found or incorrect version, will install required .net runtime in default location '$destinationPath'..."

        $noPathArgument = '-nopath'
        $installDirectoryArgument = '-installdir'
        $dotNetInstallerFile = if ( $isWindowsOS ) {
            'dotnet-install.ps1'
        } else {
            $noPathArgument = '--nopath'
            $installDirectoryArgument = '--installdir'
            'dotnet-install.sh'
        }

        $dotNetInstallerPath = join-path $destinationPath $dotNetInstallerFile

        if ( ! ( test-path $dotNetInstallerPath ) ) {
            $installerUri = if ( $isWindowsOS ) {
                'https://dot.net/v1/dotnet-install.ps1'
            } else {
                'https://dot.net/v1/dotnet-install.sh'
            }

            Write-Progress -ParentId 1 -Id 2 -Activity 'Downloading .net installer script' -PercentComplete 5
            write-verbose "Downloading .net installer script to '$dotNetInstallerPath'..."
            Invoke-WebRequest -usebasicparsing $installerUri -OutFile $dotNetInstallerPath
            if ( ! $isWindowsOS ) {
                & chmod +x $dotNetInstallerPath
            }
        }

        # Installs runtime and SDK
        Write-Progress -ParentId 1 -Id 2 -Activity 'Installing dotnet tool' -PercentComplete 10
        write-verbose 'Installing new .net version...'
        (invoke-expression "$dotNetInstallerPath $noPathArgument $installDirectoryArgument $dotNetDirectory") | write-verbose

        Write-Progress -ParentId 1 -Id 2 -Activity 'Verifying dotnet installation' -PercentComplete 100

        $existingDotNetToolPath = $privateDotNetPath

        $dotNetToolFinalVerification = test-path $existingDotNetToolPath

        if ( ! $dotNetToolFinalVerification ) {
            throw "Unable to install or detect required .net runtime tool 'dotnet' at location '$dotNetInstallerPath'"
        }

        # WORKAROUND: Again, working around global.json as described earlier.
        $newDotNetVersion = try {
            pushd /
            (& $privateDotNetPath --version)
        } finally {
            popd
        }
        write-verbose "After installation dotnet version '$newDotNetVersion' detected..."
    }

    $existingDotNetToolPath
}
