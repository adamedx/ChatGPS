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

using Microsoft.Extensions.Logging;

namespace Modulus.ChatGPS.Logging;

internal class LoggerLogWriter : ILogWriter
{
    internal LoggerLogWriter(ILoggerFactory? loggerFactory)
    {
        if ( loggerFactory is not null )
        {
            this.logger = loggerFactory.CreateLogger("Modulus.ChatGPS.AIProxy");
        }
    }

    public void Open()
    {
    }

    public void Write( string outputString, LogLevel logLevel = LogLevel.Debug )
    {
        this.logger?.Log(logLevel, outputString);
    }

    public void Close()
    {
    }

    public void Flush()
    {
    }

    ILogger? logger;
}
