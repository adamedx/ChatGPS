//
// Copyright (c), Adam Edwards
//
// All rights reserved.
//

using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.SemanticKernel;

namespace Modulus.ChatGPS.Models.Proxy;

public class ProxyResponse : ProxyMessage
{
    public enum ResponseType
    {
        Normal,
        WhatIf
    }

    public enum ResponseStatus
    {
        Unknown,
        Success,
        Error
    }

    public class Operation
    {
        public enum OperationStatus
        {
            Synthetic,
            NotStarted,
            Succeeded,
            Error
        }

        public Operation(string? name = null)
        {
            this.Status = OperationStatus.Synthetic;
            this.Name = name;
        }

        public Operation(string name, Exception operationException)
        {
            this.Name = name;
            this.OperationException = operationException;
        }

        public Operation(string name, Func<Operation, string?> operationFunction)
        {
            this.Name = name;
            this.status = OperationStatus.NotStarted;
            this.operationFunction = operationFunction;
        }

        public void Invoke()
        {
            if ( this.Status == OperationStatus.Synthetic )
            {
                throw new InvalidOperationException("A synthetic operation may not be invoked");
            }

            if ( this.Status != OperationStatus.NotStarted )
            {
                throw new InvalidOperationException("This operation has already completed");
            }

            if ( this.operationFunction is null )
            {
                throw new InvalidOperationException("This operation does not have an assigned function");
            }

            try
            {
                this.Result = this.operationFunction.Invoke(this);
                this.Status = OperationStatus.Succeeded;
            }
            catch (Exception e)
            {
                this.OperationException = e;
                this.Status = OperationStatus.Error;
            }
        }

        public string? Name { get; set; }

        public string? Result
        {
            get
            {
                if ( this.Status == OperationStatus.Synthetic )
                {
                    throw new InvalidOperationException("A synthetic operation may not have a result");
                }

                return this.result;
            }

            set
            {
                if ( this.Status == OperationStatus.Synthetic )
                {
                    throw new InvalidOperationException("A synthetic operation may not have a result");
                }

                this.Status = OperationStatus.Succeeded;
                this.result = value;
            }
        }

        public OperationStatus Status
        {
            get
            {
                return this.status;
            }

            set
            {
                if ( this.status == OperationStatus.Synthetic )
                {
                    throw new InvalidOperationException("The status of a synthetic operation may not be altered");
                }

                this.status = value;
            }
        }

        public Exception? OperationException
        {
            get
            {
                return this.exception;
            }

            set
            {
                this.status = OperationStatus.Error;
                this.exception = value;
            }
        }

        private string? result;
        private Exception? exception;
        private OperationStatus status;
        private Func<Operation, string?>? operationFunction;
    }

    public class ExecutionPlan
    {
        public ExecutionPlan() {}

        public ExecutionPlan(Operation[] operations)
        {
            this.Operations = operations;
        }

        public Operation[]? Operations;
    }

    public ProxyResponse()
    {
        this.Type = ResponseType.WhatIf;
    }

    public ProxyResponse(Guid requestId, ResponseStatus status, string[] serializedResponses, AIServiceException[] exceptions)
    {
        this.Status = ResponseStatus.Success;
        this.Content = serializedResponses;
        this.Exceptions = exceptions;
        this.Type = ResponseType.Normal;
        this.RequestId = requestId;
        this.Status = status;

        Validate();
    }

    public ProxyResponse(Guid requestId, ResponseStatus status, Operation[] operations)
    {
        this.Type = ResponseType.WhatIf;
        this.Status = ResponseStatus.Success;
        this.Plan = new ExecutionPlan(operations);
        this.Content = null;
        this.RequestId = requestId;
        this.Status = status;

        Validate();
    }

    public string Serialize()
    {
        Validate();
        return ( this.Content is not null ) ? ( this.Content.ToString() ?? "" ) : "";
    }

    public static CommandResponse? GetCommandResponseFromProxyResponse(ProxyResponse proxyResponse, Type commandType)
    {
        proxyResponse.Validate();
        proxyResponse.ValidateTargetServiceResponse();

        CommandResponse? result = null;

        if ( proxyResponse.Content is not null && proxyResponse.Content[0] is not null )
        {
            result = (CommandResponse?) JsonSerializer.Deserialize(proxyResponse.Content[0], commandType, ProxyMessage.jsonOptions);
        }

        return result;
    }

    private void Validate()
    {
        if ( this.Status == ResponseStatus.Unknown )
        {
            throw new ArgumentException($"The response status '{this.Status}' is not valid.");
        }

        if ( this.Content is not null && this.Plan is not null )
        {
            throw new ArgumentException("The response may not contain both a plan and content");
        }

        if ( this.Type == ResponseType.Normal && this.Plan is not null )
        {
            throw new ArgumentException("A normal response may not contain a plan");
        }

        if ( this.Type == ResponseType.WhatIf && this.Content is not null )
        {
            throw new ArgumentException("A whatif response may not contain content");
        }
    }

    void ValidateTargetServiceResponse()
    {
        if ( this.Status != ProxyResponse.ResponseStatus.Success )
        {
            Exception? requestException = this.Exceptions != null && this.Exceptions.Length > 0 ? this.Exceptions[0] : null;

            if ( requestException is not null )
            {
                throw requestException;
            }
            else
            {
                throw new AIServiceException("The request to the AI service failed for an unknown reason");
            }
        }
    }

    public AIServiceException[]? Exceptions {
        get
        {
            return this.exceptions;
        }

        set
        {
            if ( this.exceptions is not null )
            {
                throw new InvalidOperationException("This operation's exception status may not be set more than once.");
            }

            this.exceptions = value;

            if ( value is not null && value.Length > 0 )
            {
                this.Status = ResponseStatus.Error;
            }
        }
    }

    public ResponseStatus Status { get; set; }
    public ResponseType Type { get; set; }
    public string[]? Content { get; set; }
    public ExecutionPlan? Plan { get; set; }
    public Guid RequestId { get; set; }

    private AIServiceException[]? exceptions;
}
