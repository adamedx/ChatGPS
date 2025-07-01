#
# Copyright (c) Adam Edwards
#
# All rights reserved.
#

function GetPluginParameterInfo(
    [string] $pluginProviderName,
    [HashTable] $parameterTable = $null,
    [string[]] $parameterNameList = $null,
    [string[]] $parameterValueList = $null,
    [string[]] $allowedUnencryptedList = $null,
    [bool] $interactiveEncryptedParameters = $false
) {
    $provider = [Modulus.ChatGPS.Plugins.PluginProvider]::GetProviderByName($pluginProviderName)

    if ( $parameterTable -and $parameterNameList ) {
        throw [ArgumentException]::new("A parameter table and a parameter list may not both be specified, only one may be specified.")
    }

    if ( ( $null -eq $parameterNameList ) -ne ( $null -eq $parameterValueList ) ) {
        throw [ArgumentException]::new("A parameter list and parameter values must both be specified or neither must be specified")
    }

    $specifiedParameterNames = @()
    $specifiedParameterValues = @()

    if ( $parameterNameList ) {
        if ( $parameterNameList.Length -ne $parameterValueList.length ) {
            throw [ArgumentException]::new("The parameter name list length of $($parameterNameList.Length) did not match the parameter value list length of $($parameterValueList.Length). If the parameter is to be read from the console as an encrypted parameter, it must still be specified with the value $null in the parameter value list.")
        }

        $specifiedParameterNames = $parameterNameList
        $specifiedParameterValues = $parameterValueList
    } elseif ( $parameterTable ) {
        $specifiedParameterNames += $parameterTable.Keys
        $specifiedParameterValues += $parameterTable.Values
    }

    $unusedParameters = @{}
    $unencryptedParameters = @{}

    $parameters = [System.Collections.Generic.Dictionary[string,Modulus.ChatGPS.Plugins.PluginParameterValue]]::new()

    foreach ( $parameter in $provider.Parameters ) {
        $unusedParameters.Add($parameter.Name, $parameter)
    }

    foreach ( $unencryptedParameter in $allowedUnencryptedList ) {
        if ( ! $unusedParameters.ContainsKey($unencryptedParameter) ) {
            throw [ArgumentException]::new("The parameter '$unencryptedParameter' was specified to be unencrypted, but is not a valid unencrypted parameter")
        }

        $unencryptedParameters.Add($unencryptedParameter, $true)
    }

    for ( $parameterIndex = 0; $parameterIndex -lt $specifiedParameterNames.Length; $parameterIndex++ ) {
        $parameterName = $specifiedParameterNames[$parameterIndex]

        if ( ! $unusedParameters.ContainsKey($parameterName) ) {
            throw [ArgumentException]::new("The specified parameter '$parameterName' is not a valid parameter for the specified plugin '$pluginProviderName'")
        }

        $specifiedParameterValue = $specifiedParameterValues[$parameterIndex]

        $isEncrypted = $unusedParameters[$parameterName].Encrypted -and ! $unencryptedParameters.ContainsKey($parameterName)

        $readEncryptedValue = $isEncrypted -and
            $interactiveEncryptedParameters -and
            ( $null -eq $specifiedParameterValue )

        $parameterData = if ( $isEncrypted ) {
            if ( $readEncryptedValue ) {
                Read-Host "ChatGPS Plugin '$($pluginProviderName)', parameter $($parameterName)" -AsSecureString |
                  ConvertFrom-SecureString
            } else {
                $specifiedParameterValue
            }
        } else {
            $specifiedParameterValue
        }

        $parameterValue = [Modulus.ChatGPS.Plugins.PluginParameterValue]::new($parameterData, $isEncrypted)

        $parameters.Add($parameterName, $parameterValue)

        $unusedParameters.Remove($parameterName)
    }

    foreach ( $unusedParameterName in $unusedParameters.Keys ) {
        if ( $unusedParameters[$unusedParameterName].Required ) {
            throw [ArgumentException]::new("The required parameter '$unusedParameterName' for the plugin '$pluginProviderName' was not specified.")
        }
    }

    $parameters
}
