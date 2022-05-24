function Get-ADGraphCache {
    <#
    .SYNOPSIS
    Queries information from the Active Directory and caches them.

    .DESCRIPTION
    Queries information from the Active Directory and caches them.
    This includes all users and groups of the named domain.

    .PARAMETER Domain
    The Domain which should be queried. This is used to connect to the server.

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
        [ValidateSet("Array", "HashTable")]
        [Parameter(Mandatory = $true)]
        $ReturnType
    )
    if (!$global:ADGraphCacheTable) { $global:ADGraphCacheTable = @{} }
    $domainKey = $Domain -join ";"
    Write-PSFMessage "Query AD-Cache-Data, domainKey=$domainKey and ReturnType=$ReturnType"
    if ($global:ADGraphCacheTable.Contains($domainKey)) {
        Write-PSFMessage "Information cached"
        $cacheData = $global:ADGraphCacheTable[$domainKey]
    }
    else {
        Write-PSFMessage "Initial query"
        $allExistingGroupsAndUsers = @()
        foreach ($targetDomain in $Domain) {
            $allExistingGroupsAndUsers += Get-ADUser -filter { ( (ObjectClass -eq "user") -and (objectCategory -eq "Person")) } -properties CanonicalName, SamAccountName, Displayname, Description, memberOf, ObjectClass -server $targetDomain
            $allExistingGroupsAndUsers += Get-ADGroup -filter { (ObjectClass -eq "group") } -properties CanonicalName, SamAccountName, Displayname, Description, memberOf, members, ObjectClass -server $targetDomain
        }
        # Save all groups/users in one HashTable
        $allExistingGroupsAndUsersHash = @{ }
        $allExistingGroupsAndUsers | ForEach-Object { $allExistingGroupsAndUsersHash.Add($_.DistinguishedName, $_) }
        $cacheData = @{
            "Array"     = $allExistingGroupsAndUsers
            "HashTable" = $allExistingGroupsAndUsersHash
        }
        # $cacheData.add("Array",$allExistingGroupsAndUsers )
        # $cacheData.add("HashTable",$allExistingGroupsAndUsersHash)
        $global:ADGraphCacheTable[$domainKey] = $cacheData
    }
    $cacheData[$ReturnType]
}