//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using System.Threading;

namespace Modulus.ChatGPS.Models;

public class NativeFunction
{
    public enum FunctionType
    {
        Intrinsic,
        PowerShell
    }

    public NativeFunction() {}

    public NativeFunction(NativeFunction source) {}

    static NativeFunction()
    {
        NativeFunction.intrinsics = new Dictionary<string, Func<NativeFunction, object[]>>();
    }

    internal NativeFunction(string functionId, string scriptCode)
    {
        throw new NotImplementedException("Non-intrinsics are not yet implemented");
    }

    public string? FunctionId
    {
        get
        {
            return this.functionId;
        }

        set
        {
            if ( value is null )
            {
                this.functionId = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }
    public string? ScriptCode
    {
        get
        {
            return this.scriptCode;
        }

        set
        {
            if ( value is null )
            {
                this.scriptCode = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }

    public string? Name
    {
        get
        {
            return this.name;
        }

        set
        {
            if ( value is null )
            {
                this.name = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }

    public string? Description
    {
        get
        {
            return this.description;
        }

        set
        {
            if ( value is null )
            {
                this.description = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }

    internal Delegate? IntrinsicImplementation
    {
        get
        {
            return this.intrinsicImplementation;
        }

        set
        {
            if ( value is null )
            {
                this.intrinsicImplementation = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }

    internal FunctionType? Type
    {
        get
        {
            return this.functionType;
        }

        set
        {
            if ( value is null )
            {
                this.functionType = value;
            }
            else
            {
                throw new InvalidOperationException("The object may not be updated; it is already initialized");
            }
        }
    }

    internal static void AddIntrinsic(
        string name,
        Func<NativeFunction, object[]> creator)
    {
        NativeFunction.intrinsics.Add(name, creator);
    }

    private static Dictionary<string, Func<NativeFunction, object[]>> intrinsics;

    internal NativeFunction(string functionId, Delegate intrinsicImplementation, string description)
    {
        this.functionType = FunctionType.Intrinsic;
        this.intrinsicImplementation = intrinsicImplementation;
        this.functionId = functionId;
        this.name = functionId;
        this.description = description;
    }

    private Delegate? intrinsicImplementation;
    private string? scriptCode;
    private string? functionId;
    private string? name;
    private string? description;
    private FunctionType? functionType;
}
