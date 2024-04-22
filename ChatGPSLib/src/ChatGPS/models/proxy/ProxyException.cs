//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

public class ProxyException : Exception
{
    public ProxyException(string? message, Exception innerException) : base(message, innerException) {}
}
