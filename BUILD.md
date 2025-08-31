Building ChatGPS
================

## Prerequisites

* Clone the repository, e.g. from PowerShell `git clone https://github.com/adamedx/ChatGPS`
* Install the [.NET 9 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/9.0)

## Build

* Start a PowerShell 7 session -- the environment must be configured with the .NET tools described earlier
* Set the current working directory to the root of this cloned repository, e.g. `cd ~/src/ChatGPS`
* Execute the standard .net SDK build command:

```powershell
dotnet build
```

This will build the default configuration, which is `Debug`. To build the release configuration instead, add the following parameters to the command above: `--configuration release`.

For troubleshooting build errors, you can append `--verbosity detailed` to the command to obtain additional debug output that can identify specific errors in the build.

This will produce an importable PowerShell module with a relative path to the repository root like `./ChatGPS/bin/Debug/net8.0/Module/ChatGPS`.

## Testing

### Unit testing

Unit tests are invoked using a custom build steps that installs test dependencies, namely the [Pester](https://www.powershellgallery.com/packages/Pester) unit testing framework, before running the tests. To execute the unit tests, invoke the following PowerShell command from the root of the repository:

```powershell
dotnet msbuild ./ChatGPS/ChatGPS.csproj --target:UnitTestPowerShellModule -verbosity:detailed
```

Note that this command uses the default configuration of `Debug` to test, so if you built the `Release` configuration then add the additional parameters `--configuration release` to test the release configuration. The use of `-verbosity:detailed` allows you to see the output of the test framework; this is optional if you're only interested in a total pass / fail of the tests and do not need to debug individual test case failures.

This method of execution is exactly what the repository's CI pipeline invokes when evaluating pull request quality.

#### Run unit tests directly

For faster iteration, you can initialize the test environment separately from the test run, and then run Pester directly using the `Initialize-Tools.ps1` build script:

```powershell
& ./build/Initialize-Tools.ps1 -TestTargetModuleDirectory ./ChatGPS/ChatGPS/bin/Debug\net8.0/Module/ChatGPS -ToolsRootPath ./ChatGPS/ChatGPS/tools -ToolsModuleName Pester -ToolsModuleVersion 5.5.0
```

The `Initialize-Tools` command will install a particular version of Pester for you isolated from the version that is installed on your system. It also imports the module you've built using the value specified for the `TestTargetModuleDirectory` parameter (customize the path with a `Release` segment instead of `Debug` if you are testing the release build) and will use the Pester version specified for `ToolsModuleVersion`. You can also see how this is used in the PowerShell module's dotnet [project specification](ChatGPS/ChatGPS.csproj); this in turn is what is invoked for CI through the repository's [CI pipeline](azure-pipelines.yml).

Note that using this script is not a requirement for testing -- you can indeed install Pester manually for instance, but then your test results will be influenced by the larger state of the system, and if the version of Pester required for this project differs from versions in other software you're building on the same system, you may end up with conflicts or hard to debug failures / intermittent issues. Given that this script is what is used by the CI pipeline, using it or simply using the `dotnet msbuild` step given earlier gives higher confidence that your test results will be the same as those for the CI pipeline.

### Ad hoc / manual testing

To test manually, start a new PowerShell session and import the built module with the following command -- this example assumes that you've built the the `debug` configuration, so if you want to test the release configuration substitute the path segment `Debug` with `Release`:

```powershell
import-module ./ChatGPS/bin/Debug\net8.0/Module/ChatGPS/ChatGPS.psd1
```

Once you successfully execute the build step mentioned above you can test resulting PowerShell module build output.

The standard pattern for using the module is to first create a "chat session" context using the `Connect-ChatSession` command,
and then issue a command such as `Send-ChatMessage` to send a single message within the curretn session context
and receive a response:

```powershell

Connect-ChatSession -ApiEndpoint https://myposh-test-2024-12.openai.azure.com -DeploymentName gpt-4o-mini
Send-ChatMessage 'Hello!'

Received                 Response
--------                 --------
9/15/2024 3:44:07 PM     Hello! I'm here to help you with anything related to PowerShell. What would you like to
                         learn or discuss today?
```

In this example, a session was created using a locally hosted model stored at the file system path specified by the `LocalModelPath`
parameter. Subsequent invocations of `Send-ChatMessage` or `Start-ChatShell` (alias `chatgps`) can be used to continue the conversation with further messages.
