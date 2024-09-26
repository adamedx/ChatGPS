//
// Copyright 2023, Adam Edwards
//
// All rights reserved.
//

using System.Collections.Generic;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

using Modulus.ChatGPS.Models;

namespace Modulus.ChatGPS.Services;

public class OpenAIChatService : IChatService
{
    public OpenAIChatService(AiOptions options)
    {
        this.options = options;
    }

    public ChatHistory CreateChat(string prompt)
    {
        return new ChatHistory(prompt);
    }

    public async Task<IReadOnlyList<ChatMessageContent>> GetChatCompletionAsync(ChatHistory history)
    {
        IReadOnlyList<ChatMessageContent> result;

        try
        {
            result = await GetChatCompletionService().GetChatMessageContentsAsync(history);
        }
        catch (Exception exception)
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    public async Task<FunctionOutput> InvokeFunctionAsync(string definitionPrompt, Dictionary<string,object?>? parameters)
    {
        var kernelFunction = GetKernel().CreateFunctionFromPrompt(definitionPrompt);

        var kernelArguments = new KernelArguments(parameters ?? new Dictionary<string,object?>());

        var result = await GetKernel().InvokeAsync(kernelFunction, kernelArguments);

        return new FunctionOutput(result);
    }

        private KernelFunction CreateFunction(string definitionPrompt)
    {
        var kernel = GetKernel();

        var requestSettings = new OpenAIPromptExecutionSettings();

        KernelFunction result;

        try
        {
            result = kernel.CreateFunctionFromPrompt(definitionPrompt, executionSettings: requestSettings);
        }
        catch ( Exception exception )
        {
            throw new AIServiceException(exception);
        }

        return result;
    }

    private Kernel GetKernel()
    {
        if ( this.serviceKernel != null )
        {
            return this.serviceKernel;
        }

        if ( this.options.ModelIdentifier == null )
        {
            throw new ArgumentException("An identifier for the language model must be specified.");
        }

        var builder = Kernel.CreateBuilder();

        if ( this.options.Provider is null || this.options.Provider == ModelProvider.AzureOpenAI )
        {
            if ( this.options.ApiEndpoint == null )
            {
                throw new ArgumentException("An API endpoint must be specified.");
            }

            if ( this.options.ApiKey == null )
            {
                throw new ArgumentException("An API key for the AI service must be specified.");
            }

            builder.AddAzureOpenAIChatCompletion(
                this.options.ModelIdentifier,
                this.options.ApiEndpoint.ToString(),
                this.options.ApiKey);
        }
        else if ( this.options.Provider == ModelProvider.LocalOnnx )
        {
            if ( this.options.LocalModelPath == null )
            {
                throw new ArgumentException("A file system path must be specified.");
            }

            #pragma warning disable SKEXP0070
            builder.AddOnnxRuntimeGenAIChatCompletion(this.options.ModelIdentifier, this.options.LocalModelPath);
            #pragma warning restore SKEXP0070

            var assemblyLoader = new OnnxProviderAssemblyLoader();

            if ( ! assemblyLoader.IsSupportedOnCurrentPlatform )
            {
                throw new PlatformNotSupportedException("This application does not support the use of Onnx local models on the current system platform.");
            }
        }
        else
        {
            throw new ArgumentException($"An model of unknown type '{this.options.Provider}' was specified.");
        }

        var newKernel = builder.Build();

        if ( newKernel == null )
        {
            throw new ArgumentException("Unable to initialize AI service parameters with supplied arguments");
        }

        this.serviceKernel = newKernel;

        return newKernel;
    }

    private IChatCompletionService GetChatCompletionService()
    {
        if ( this.chatCompletionService is null )
        {
            Kernel kernel;

            try
            {
                kernel = GetKernel();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }

            try
            {
                this.chatCompletionService = kernel.GetAllServices<IChatCompletionService>().FirstOrDefault();
            }
            catch (Exception exception)
            {
                throw new AIServiceException(exception);
            }
        }

        if ( this.chatCompletionService is null )
        {
            throw new InvalidOperationException("A null result was obtained for the chat completion service");
        }

        return this.chatCompletionService;
    }

    private Kernel? serviceKernel;
    private IChatCompletionService? chatCompletionService;
    private AiOptions options;
}
