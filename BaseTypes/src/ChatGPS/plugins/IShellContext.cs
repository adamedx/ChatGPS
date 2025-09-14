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

using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace Modulus.ChatGPS.Plugins;

public interface IShellContext
{
    public void Update(string currentDirectoryPath);

    public void Update(IShellContext? shellContext);

    public int? ProcessId { get; }

    public string? ProcessName { get; }

    public string? PSVersion { get; }

    public string? UICulture { get; }

    public string? HistoryFilePath { get; }

    public string? CurrentDirectory { get; }

    public string? TranscriptPath { get; }

    public string? OperatingSystem { get; }
}
