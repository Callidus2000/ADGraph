function Add-ADGraphEdge {
    <#
    .SYNOPSIS
    Helper function which determines all Edges (aka relations) of a given DistinguishedName.

    .DESCRIPTION
    Helper function which determines all Edges (aka relations) of a given DistinguishedName.
    It uses recursive calling patterns.

    .PARAMETER StartObjectDN
    The DistinguishedName of the object which should be inspected.

    .PARAMETER RecursionLevel
    FailSafe for detection of circle relationships.

    .PARAMETER linkAttribute
    Should be members/memberOf be followed?

    .EXAMPLE
    Add-ADGraphEdge -startObjectDN "CN=joe,OU=Users,DC=mydomain,DC=com"

    Queries all relationships of the given user.

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory=$true)]
        $StartObjectDN,
        $RecursionLevel = 0,
        [ValidateSet("memberOf", "members")]
        $LinkAttribute = "memberOf"
    )
    Write-PSFMessage -String 'Add-ADGraphEdge.Start' -StringValues ($RecursionLevel), $StartObjectDN, $LinkAttribute
    if ($RecursionLevel -gt 20) { throw [ADGraphCircleException ]::new("Zirkelbezug, Level $RecursionLevel erreicht") }
    $newEdges = @()
    $startObject = $allExistingGroupsAndUsersHash[$StartObjectDN]
    Write-PSFMessage -Level Debug -String 'Add-ADGraphEdge.startObject' -StringValues $startObject
    try {
        $linkDNlist = $startObject | Select-Object -ExpandProperty $LinkAttribute -ErrorAction Stop
    }
    catch {
        Write-PSFMessage "Could not find attribute $LinkAttribute"
    }
    foreach ($linkDN in $linkDNlist) {
        $memberObject = $allExistingGroupsAndUsersHash[$linkDN]
        $attributes = @{ }
        # if (($startObject.ObjectClass -ne "user") -and ($memberObject.Epoche -ne $startObject.Epoche)) {
        #     Write-PSFMessage -Level Debug -String 'Add-ADGraphEdge.differentTimeline' -StringValues $StartObjectDN, $linkDN
        #     $attributes.add("color", "red")
        # }
        if ($LinkAttribute -eq "memberOf") {
            # MemberOf Beziehung von Links nach Rechts
            $currentEdge = [ADGraphEdge]::new([PSCustomObject]@{
                    from       = $StartObjectDN
                    to         = $linkDN
                    attributes = $attributes
                    fromObject = $startObject
                    toObject   = $memberObject
                }
            )
            $newEdges += $currentEdge
        }
        else {
            # Members Beziehung von Rechts nach Links
            $currentEdge = [ADGraphEdge]::new([PSCustomObject]@{
                    from       = $linkDN
                    to         = $StartObjectDN
                    attributes = $attributes
                    fromObject = $memberObject
                    toObject   = $startObject
                }
            )
            $newEdges += $currentEdge
        }
        try {
            $newEdges += Add-ADGraphEdge -startObjectDN $linkDN -recursionLevel ($RecursionLevel + 1) -linkAttribute $LinkAttribute
        }
        catch [ADGraphCircleException] {
            $circleError = $PSItem.Exception
            if ($RecursionLevel -gt 0) {
                $circleError.AddErrorEdge($currentEdge)
                $circleError.AddExistingEdges($newEdges)

                throw $circleError
            }
            else {
                $newEdges += $circleError.ExistingEdges
                return $newEdges
            }
        }
    }
    $newEdges
}