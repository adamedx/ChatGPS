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


namespace Modulus.ChatGPS.Logging;

public class ProxyLogger
{
    public static Microsoft.Extensions.Logging.LogLevel ToStandardLogLevel(LogLevel logLevel)
    {
        var standardLogLevel = logLevel switch
        {
            LogLevel.Default => Microsoft.Extensions.Logging.LogLevel.Debug,
            LogLevel.None => Microsoft.Extensions.Logging.LogLevel.None,
            LogLevel.Error => Microsoft.Extensions.Logging.LogLevel.Error,
            LogLevel.Warning => Microsoft.Extensions.Logging.LogLevel.Warning,
            LogLevel.Debug => Microsoft.Extensions.Logging.LogLevel.Debug,
            LogLevel.DebugVerbose => Microsoft.Extensions.Logging.LogLevel.Trace,
            _ => Microsoft.Extensions.Logging.LogLevel.None
        };

        return standardLogLevel;
    }
}

