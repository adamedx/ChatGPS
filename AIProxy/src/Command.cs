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

using Modulus.ChatGPS.Models;
using Modulus.ChatGPS.Models.Proxy;

//
// Note that we can't inherit from an interface because
// any methods implemented for an interface MUST be
// public according to some arbitrary C# rule or you
// end up with error CS0737. We were going to have this
// abstract class inherit from it, but since everyone
// is going to inherit from this abstract class, we
// might as well just pretend this class is the interface. :)
//

internal abstract class Command
{
    protected Command(CommandProcessor processor)
    {
        this.processor = processor;
    }

    internal abstract ProxyResponse.Operation[] Process(CommandRequest? commandRequest, bool whatIf = false);

    protected CommandProcessor processor;
}

