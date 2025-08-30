| [Documentation](ChatGPS/docs/Introduction.md) | [Development](#development-and-testing) | [Command reference](ChatGPS/docs/CommandReference.md) |
|-------------|-------------|-------------|

# <img src="ChatGPS/assets/ChatGPS.png" width="50"> ChatGPS

[![Build Status](https://adamedx.visualstudio.com/ChatGPS/_apis/build/status%2Fadamedx.ChatGPS?branchName=main)](https://adamedx.visualstudio.com/ChatGPS/_build/latest?definitionId=7&branchName=main)

**ChatGPS** enhances your interactive and scripted PowerShell sessions with artificial intelligence. With ChatGPS you can:

* **Generate PowerShell scripts** from words, not code
* **Incorporate AI** into PowerShell-based automation
* **Build agents:** enable language models to use specific PowerShell scripts on your system
* **Chat interactively** with language models without leaving your PowerShell terminal

ChatGPS supports several AI model providers such as OpenAI, Azure OpenAI, Anthropic, Google, etc. This includes support for local providers like Onnx and Ollama among others.

```powershell
PS > Connect-ChatSession -ApiEndpoint https://searcher-2024-12.openai.azure.com -DeploymentName gpt-4o-mini -ReadApiKey
ChatGPS: Enter secret key / password>: *****************

PS > Send-ChatMessage 'Hello World!'

Received                 Response
--------                 --------
3/11/2025 10:10:16 PM    Hello! How can I assist you today?
```

ChatGPS is built on [Semantic Kernel (SK)](https://github.com/microsoft/semantic-kernel), and works well with models and AI capabilities supported by SK.

# Installation

```powershell
# TBD!!!
```

# Prerequisites

To use ChatGPS, you'll need:
* [PowerShell](https://github.com/PowerShell/PowerShell) 7.4 and higher on Windows, Linux, or MacOS
* Models -- bring your own!
  * Remote: valid account credentials to a service like Azure OpenAI, OpenAI, Anthropic, etc.
  * Local: for locally hosted models including [Onnx](https://onnx.ai) and [Ollama](https://ollama.com), GPU or NPU capabilities may be needed depending on the specific model. Local models typically require the installation of client software before ChatGPS can use them, see the documentation for the [Connect-ChatSession](ChatGPS/docs/commands/Connect-ChatSession.md) command for details.

## Supported model providers

The following providers are supported by ChatGPS; in some cases a providers outside of this list that expose the same API as a supported provider (e.g.OpenAI) or use the same inferencing libraries may also work with ChatGPS:

|Provider     |Sample models                |Notes                                                    |
|-------------|-----------------------------|---------------------------------------------------------|
|Anthropic    |Claude Sonnet et. al.        |Plugin support currently unreliable                      |
|Azure OpenAI |GPT 4, GPT4o, custom         |Supports any model you've deployed using Azure           |
|Google       |Gemini 2.0, Gemini 2.5, etc. |                                                         |
|Ollama       |llama3, etc                  |Local models, requires Ollama client                     |
|Onnx         |Phi 3.5, Phi 4, etc.         |Local models, ChatGPS will install via Install-ChatAddOn |
|OpenAI       |GPT 4, GPT 4o, etc.          |Can be used with many models other than OpenAI           |

For more details, see the detailed [documentation](ChatGPS/docs/Introduction.md).

# Acknowledgments / attribution

* The [text to ASCII art generator](https://www.asciiart.eu/text-to-ascii-art) by [AsciiArtEU](https://www.asciiart.eu/link-to-us) was used to generate some of this project's ASCII art.

License and authors
-------------------
Copyright:: Copyright (c) Adam Edwards

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

