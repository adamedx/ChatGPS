<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup Condition=" '$(TargetFramework)' == 'net8.0' ">
    <PackageReference Include="Microsoft.SemanticKernel.Connectors.Onnx" Version="1.59.0-alpha" />
  </ItemGroup>

  <Target Name="AnyTargetDependencies">
    <PropertyGroup>
      <LibDirectory>tmplib</LibDirectory>
      <DevLibDirectory>$(ProjectDir)/$(LibDirectory)</DevLibDirectory>
    </PropertyGroup>
  </Target>

  <Target Name="DevModule" AfterTargets="Build" DependsOnTargets="Build;AnyTargetDependencies">
    <MakeDir Directories="$(DevLibDirectory)" />
    <ItemGroup>
      <AssemblyDependencies Include="$(TargetDir)*.dll;$(TargetDir)*.exe;$(TargetDir)*.runtimeconfig.json;$(TargetDir)*.deps.json" Exclude="$(TargetDir)$(ProjectName).dll;$(TargetDir)/ChatGPS.exe;$(TargetDir)/ChatGPS.*.json"/>
      <AssemblyIndirectDependencies Include="$(TargetDir)/runtimes/**/*" Exclude="$(TargetDir)/runtimes/android/**/*;$(TargetDir)/runtimes/ios/**/*;$(TargetDir)/runtimes/osx-x64/**/*;$(TargetDir)/runtimes/win-x86/**/*;"/>
    </ItemGroup>
    <Copy SourceFiles="$(TargetPath)" DestinationFolder="$(DevLibDirectory)"/>
    <Copy SourceFiles="@(AssemblyDependencies)" DestinationFolder="$(DevLibDirectory)"/>
    <Copy SourceFiles="@(AssemblyIndirectDependencies)" DestinationFolder="$(DevLibDirectory)/runtimes/%(RecursiveDir)"/>
  </Target>


</Project>
