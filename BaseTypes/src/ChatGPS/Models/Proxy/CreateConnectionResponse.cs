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

namespace Modulus.ChatGPS.Models.Proxy;

public class CreateConnectionResponse : CommandResponse
{
    public CreateConnectionResponse() {}
    public CreateConnectionResponse( Guid id, AiOptions currentOptions )
    {
        this.ConnectionId = id;
        this.CurrentOptions = new AiProviderOptions( new AiOptions(currentOptions) );
    }

    public Guid ConnectionId { get; set; }
    public AiProviderOptions? CurrentOptions { get; set; }
}

