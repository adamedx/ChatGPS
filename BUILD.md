Building ChatGPS
================

## Prerequisites

* Clone the repository, e.g. from PowerShell `git clone https://github.com/adamedx/ChatGPS`
* Install the [.NET 9 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/9.0)
* Install the `Pester` PowerShell test framework (skip this if you don't need to run tests): `install-module pester`

## Build

* Start a PowerShell 7 session -- the environment must be configured with the .NET tools described earlier
* Set the current working directory to the root of this cloned repository, e.g. `cd ~/src/ChatGPS`
* Execute the standard .net SDK build command:
```powershell
dotnet build
```
This will produce an importable PowerShell module with a relative path to the repository root like `./ChatGPS/bin/Debug/net8.0/Module/ChatGPS`.

## Testing

### Unit testing

To run the unit tests, invoke the following PowerShell command from the root of the repository:

```powershell
import-module ./ChatGPS/bin/Debug\net8.0/Module/ChatGPS/ChatGPS.psd1
invoke-pester
```

### Ad hoc / manual testing

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
