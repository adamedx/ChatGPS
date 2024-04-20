//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

internal interface ICommand
{
    string? Process(string[] arguments);
}
