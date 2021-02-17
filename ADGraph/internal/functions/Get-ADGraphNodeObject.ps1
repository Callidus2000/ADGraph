function Get-ADGraphNodeObject {
    <#
    .SYNOPSIS
    Determines the unique ADGraphNode objects from given ADGraphEdges.

    .DESCRIPTION
    Determines the unique ADGraphNode objects from given ADGraphEdges.

    .PARAMETER StartObjectDN
    The DistinguishedName of the starting point

    .PARAMETER Edges
    Array of all Edges

    .EXAMPLE
    Get-ADGraphNodeObject -edges (Add-ADGraphEdge -startObjectDN $startObject) -startObjectDN $startObject
    Determines the nodes for the $startObject

    .NOTES
    General notes
    #>
    param (
        [string]$StartObjectDN,
        [ADGraphEdge[]]$Edges
    )
    Write-PSFMessage "Ermittele Nodes von startObjectDN=$StartObjectDN und edges=$($Edges.count)"
    $nodeDNs = @()
    $nodeObjects = @()
    $nodeDNs += ($Edges | Select-Object -ExpandProperty from)
    $nodeDNs += ($Edges | Select-Object -ExpandProperty to)
    $nodeDNs = $nodeDNs | Select-Object -Unique
    foreach ($DistinguishedName in $nodeDNs) {
        $currentNodeObject = $allExistingGroupsAndUsersHash[$DistinguishedName]
        # Aktuelle Node als Objekt initiieren, Formatierung passiert im Constructor
        $node = [ADGraphNode]::new($DistinguishedName, $currentNodeObject)
        $nodeObjects += $node
        # Das Start-Objekt erhält eine getrennte Formatierung
        if ($currentNodeObject.DistinguishedName -eq $StartObjectDN) {
            $node.attributes.fillcolor = "cyan"
            $node.attributes.style = "filled"
        }
    }
    # Falls keine Beziehungen vorhanden sind, wäre die Liste der Nodes leer. Hier wird ein Startobjekt angelegt.
    if ($nodeObjects.count -eq 0) {
        $nodeObjects += [ADGraphNode]::new($StartObjectDN, $allExistingGroupsAndUsersHash[$StartObjectDN] )
    }
    $nodeObjects
}
