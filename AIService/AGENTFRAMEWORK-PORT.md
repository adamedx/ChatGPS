# Microsoft Agent Framework port

This directory now uses Microsoft Agent Framework for chat completion and function calling. The PowerShell command surface is unchanged: commands such
as `Add-ChatPlugin`, `Set-ChatAgentAccess`, `Send-ChatMessage`, and `New-ChatFunction` continue to operate through the existing service and proxy
contracts.

## What changed

`AIKernel` no longer calls `IChatClient.GetResponseAsync` directly for normal chat or prompt-backed functions. It creates a `ChatClientAgent` and runs the
conversation through that agent. The provider's `IChatClient` is wrapped in `FunctionInvokingChatClient`, which is the Agent Framework middleware that
turns model tool calls into local .NET method invocations and sends the results back to the model.

The project references `Microsoft.Agents.AI` `1.0.0`, together with the compatible `Microsoft.Extensions.AI` `10.4.0` dependency set. Keeping these
versions aligned is important: the agent and function-invocation middleware use APIs from the matching Microsoft.Extensions.AI assemblies.

## Plugin support

`LocalContext`, `TimePlugin`, and `FileIOPlugin` are implemented in this port. Their native plugin instances are created from the registered providers. Public instance methods on `LocalContextNativePlugin`, `TimeNativePlugin`, and `FileIONativePlugin` are converted to Agent Framework `AITool` instances using `AIFunctionFactory`. Their method
descriptions are therefore exposed to the model without changing the plugin command interface.

Other plugin names are rejected with `NotImplementedException` rather than being silently ignored. This makes the current scope explicit and avoids
advertising tools that do not yet have Agent Framework implementations.

## Why `ChatService` and `AIKernel` both have a plugin table reference

The two references represent different responsibilities, even though they point to the same `IPluginTable` object:

* `ChatService.pluginTable` is the service/session-owned state. It represents
  the plugins registered for the session and the shell context received from
  the proxy. The service owns its lifetime and updates it as plugin and context
  synchronization occurs.
* `IAIKernel.SetPluginTable` is the hand-off boundary into the AI implementation.
  `AIKernel` needs the current table when it constructs an agent, because that
  is when it converts the registered plugin definitions into `AITool` objects.

`ChatService.GetKernelWithState()` ensures that a table exists and passes that same instance to the kernel before any operation that can create or run an
agent. The kernel does not maintain an independent copy of the plugin definitions. Consequently, plugin registrations and the proxy-provided
`IShellContext` remain session state owned by `ChatService`, while `AIKernel` only consumes that state to build the tools required by Agent Framework.

This explicit setter is needed because the kernel is created by provider-specific chat services, while the plugin table is maintained by their common base
`ChatService`. Putting plugin synchronization in the kernel would make the AI implementation responsible for PowerShell session state and would break the
existing proxy/session ownership model.

## Request flow

With agent access enabled, the proxy request carries the synchronized plugin definitions and shell context to the AI service:

1. `ChatService.GetKernelWithState()` supplies its `PluginTable` to `AIKernel`.
2. `AIKernel.CreateAgent()` creates tools for the registered `LocalContext`,
   `TimePlugin`, and `FileIOPlugin` plugins from that table.
3. `ChatOptions.ToolMode` is set to `Auto`.
4. The model may select a tool, such as `get_process_id`.
5. `FunctionInvokingChatClient` invokes the native method with the session's shell context.
6. The tool result is returned to the model, which produces the final chat response.

When agent access is disabled, no tools are supplied and tool mode is set to `None`, preserving the existing access-control behavior.

## Related interface changes

`IAIKernel` exposes `SetPluginTable` so every service implementation can receive the session-owned table through the common service path. The native
plugin factory method was made public because `AIService` is a separate project from `BaseTypes`, and the Agent Framework tool-registration code must
instantiate the selected native plugin.
