//
// Copyright (c), Adam Edwards
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

using System.IO;
using Modulus.ChatGPS.Communication;

namespace Modulus.ChatGPS.Proxy;

public class Channel : StdioChannel, IChannel
{
    public Channel(string proxyHostPath, int idleTimeoutMs = 60000, string? logFilePath = null, string? logLevel = null) :
        base(proxyHostPath)
    {
        this.idleTimeoutMs = idleTimeoutMs;
        this.logFilePath = logFilePath;
        this.logLevel = logLevel;
    }

    protected override string GetCommandArguments()
    {
        var logFilePathArgument = this.logFilePath is not null ? $"--logfile {this.logFilePath} " : "";
        var logLevelArgument = this.logLevel is not null ? $"--debuglevel {this.logLevel} " : "";

        return $"--timeout {this.idleTimeoutMs} {logLevelArgument}{logFilePathArgument}".Trim();
    }

    int idleTimeoutMs;
    string? logFilePath;
    string? logLevel;
}

