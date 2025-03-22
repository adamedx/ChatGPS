//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Plugins;

public class StaticPlugin : Plugin
{
    internal StaticPlugin(Type kernelPluginType) : base(kernelPluginType) {}
}
