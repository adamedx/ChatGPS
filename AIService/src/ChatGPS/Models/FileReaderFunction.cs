//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;

namespace Modulus.ChatGPS.Models;

internal class FileReaderFunction
{
/*    internal static Func<FileReaderFunction, object[]> Creator(object[] parameters)
   {
        return new FileReaderFunction(parameters);
    }
*/
    internal FileReaderFunction(object[] parameters)
    {
        if ( parameters.Length < 1 )
        {
            throw new ArgumentException("Missing root parameter of the FileReaderFunction");
        }

        this.rootDirectory = (string) parameters[0];
    }

    internal string GetMethod(string fileSystemLocation)
    {
        return $"This is a test file with {fileSystemLocation}.";
    }

    string rootDirectory;
}
