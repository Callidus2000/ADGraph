function Get-ADGraphCache {
    <#
    .SYNOPSIS
    Queries information from the Active Directory and caches them.

    .DESCRIPTION
    Queries information from the Active Directory and caches them.
    This includes all users and groups of the named domain.

    .PARAMETER Domain
    The Domain which should be queried. This is used to connect to the server.

    .PARAMETER Credential
    Optional credentials used for Active Directory access.

    .PARAMETER NoCache
    Forces a fresh query and bypasses cached values.

    .PARAMETER ReturnType
    Should the array of all users and groups be returned or the Indexed HashTable?

    .EXAMPLE
    Get-ADGraphCache -Domain "myDomain" -ReturnType HashTable

    Queries all Users/Groups as a HashTable

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Domain,
        [PSCredential]$Credential,
        [switch]$NoCache,
        [ValidateSet("Array", "HashTable")]
        [Parameter(Mandatory = $true)]
        $ReturnType
    )
    $collectorAllExistingGroupsAndUsers = {
        param ($CollectorArgument)

        Write-PSFMessage "Initial query for Domain=$($CollectorArgument.Domain), User=$($CollectorArgument.Credential.UserName)" -FunctionName "Get-ADGraphCache.CollectorAllExistingGroupsAndUsers"

        $adUserParameters = @{
            Filter     = { ( (ObjectClass -eq 'user') -and (objectCategory -eq 'Person')) }
            Properties = 'DistinguishedName', 'CanonicalName', 'SamAccountName', 'Displayname', 'Description', 'memberOf', 'ObjectClass'
            Server     = $CollectorArgument.Domain
        }
        $adGroupParameters = @{
            Filter     = { (ObjectClass -eq 'group') }
            Properties = 'DistinguishedName', 'CanonicalName', 'SamAccountName', 'Displayname', 'Description', 'memberOf', 'members', 'ObjectClass'
            Server     = $CollectorArgument.Domain
        }
        if ($CollectorArgument.Credential) {
            $adUserParameters.Credential = $CollectorArgument.Credential
            $adGroupParameters.Credential = $CollectorArgument.Credential
        }

        $allExistingGroupsAndUsers = @()
        $allExistingGroupsAndUsers += Get-ADUser @adUserParameters | Select-Object -Property $adUserParameters.Properties
        $allExistingGroupsAndUsers += Get-ADGroup @adGroupParameters | Select-Object -Property $adGroupParameters.Properties
        return $allExistingGroupsAndUsers
    }
    $collectorUserAndGroupHash = {
        param ($CollectorArgument)

        Write-PSFMessage "Query HashTable for Domain=$($CollectorArgument.Domain), User=$($CollectorArgument.Credential.UserName)" -FunctionName "Get-ADGraphCache.CollectorUserAndGroupHash"
        $allExistingGroupsAndUsers = Get-PSFTaskEngineCache -Module "ADGraph" -Name "$($CollectorArgument.Domain).Array"

        $allExistingGroupsAndUsersHash = @{ }
        $allExistingGroupsAndUsers | ForEach-Object { $allExistingGroupsAndUsersHash.Add($_.DistinguishedName, $_) }
        return $allExistingGroupsAndUsersHash
    }

    $moduleName = if ($ExecutionContext.SessionState.Module) { $ExecutionContext.SessionState.Module.Name } else { 'ADGraph' }
    $cacheKeySuffix = if ($ReturnType -eq 'HashTable') { 'Hash' } else { 'Array' }
    $collectorValues = foreach ($targetDomain in $Domain) {
        $collectorArgument = [PSCustomObject]@{
            Domain     = $targetDomain
            Credential = $Credential
        }
        Write-PSFMessage "Prepare cache registration for $targetDomain and Credential $credential"
        Set-PSFTaskEngineCache -Module $moduleName -Name "$targetDomain.Array" -Lifetime (New-TimeSpan -Minutes 4) -Collector $collectorAllExistingGroupsAndUsers -CollectorArgument $collectorArgument
        Set-PSFTaskEngineCache -Module $moduleName -Name "$targetDomain.Hash" -Lifetime (New-TimeSpan -Minutes 4) -Collector $collectorUserAndGroupHash -CollectorArgument $collectorArgument

        $cacheName = "$targetDomain.$cacheKeySuffix"
        Write-PSFMessage "Read cache value for $cacheName"
        Get-PSFTaskEngineCache -Module $moduleName -Name $cacheName -Verbose
    }
    Write-PSFMessage "Return $($collectorValues.count) objects from cache"
    return $collectorValues
}