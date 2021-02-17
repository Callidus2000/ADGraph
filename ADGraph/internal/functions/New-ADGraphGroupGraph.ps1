function New-ADGraphGroupGraph {
    <#
    .SYNOPSIS
    Creates a GraphViz dot graph.

    .DESCRIPTION
    Creates a GraphViz dot graph.

    .PARAMETER StartObjectDN
    The DistinguishedName of the object which should be inspected.

    .PARAMETER LinkAttribute
    Should be members/memberOf be followed?

    .PARAMETER RemoveUsers
    Should User objects be removed from the graph?

    .EXAMPLE
    New-ADGraphGroupGraph -LinkAttribute @("memberOf", "members") -StartObjectDN "CN=joe,OU=Users,DC=mydomain,DC=com"
    Gets a grpah from Joe

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    param (
        [Parameter(Mandatory)]
        [String[]]$StartObjectDN,
        [Parameter(Mandatory = $false)]
        [ValidateSet("memberOf", "members")]
        [String[]]$LinkAttribute = "memberOf",
        [switch]$RemoveUsers
    )
    Write-PSFMessage "Erstelle neuen Graphen, Start-Objekte: $($StartObjectDN -join ';'), LinkAttribute $($LinkAttribute -join ';'), RemoveUsers=$RemoveUsers"
    # Zählen, wie viele Start-Objekte verwendet werden sollen
    $measurement = $startObjectDN | Measure-Object
    if ($measurement.Count -eq 2) {
        Write-PSFMessage "Vergleich von zwei Objekten"
    }
    $compareMode = ($measurement.Count -eq 2)
    # Verknüpfungen ermitteln und als GraphViz Edges hinterlegen
    $edgeObjectArrays = 1..($measurement.Count)
    $arrayIndex = 0
    $allEdgeObjects = @()
    foreach ($startObject in $startObjectDN) {
        Write-PSFMessage "Suche Edges für $startObject"
        $edgeObjects = @()
        foreach ($linkAttr in $LinkAttribute) {
            try {
                $edgeObjects += Add-ADGraphEdge -startObjectDN $startObject -linkAttribute $linkAttr
            }
            catch [ADGraphCircleException] {
                $circleError = $PSItem.Exception
                $edgeObjects += $circleError.ExistingEdges
                Write-PSFMessage "Error, Circle Exception!" -Level Critical
            }
        }
        if ($RemoveUsers) {
            $edgeObjects = $edgeObjects | Where-Object { $_.from -notmatch 'OU=Users' }
        }
        $edgeObjectArrays[$arrayIndex] = $edgeObjects
        $allEdgeObjects += $edgeObjects
        Write-PSFMessage "edgeObjects.count=$($edgeObjects.count), arrayIndex=$arrayIndex"
        $arrayIndex += 1
    }
    Write-PSFMessage "edgeObjectArrays.count=$($edgeObjectArrays.count) Array mit Edges erstellt"
    $nodeObjectArrays = 1..($measurement.Count)
    $allNodeObjects = @()
    $arrayIndex = 0

    foreach ($startObject in $startObjectDN) {
        $nodeObjects = Get-ADGraphNodeObject -edges $edgeObjectArrays[$arrayIndex] -startObjectDN $startObject
        if ($compareMode) {
            foreach ($node in $nodeObjects) {
                $node.SpecialMarkers += "arrayIndex=$arrayIndex"
            }
        }
        $allNodeObjects += $nodeObjects
        $nodeObjectArrays[$arrayIndex] = $nodeObjects
        $arrayIndex += 1
    }
    Write-PSFMessage "$($nodeObjectArrays.count) Array mit Nodes erstellt"
    if ($compareMode) {
        # foreach ($node in $nodeObjectArrays[0]) {
        #     $node.attributes.fillcolor = "cyan"
        #     $node.attributes.style = "filled"
        # }
        foreach ($node in $nodeObjectArrays[1]) {
            if ($nodeObjectArrays[0] | Where-Object { $_.name -eq $node.name }) {
                $node.SpecialMarkers += "arrayIndex=2"
            }
            # if ($nodeObjectArrays[0] | Where-Object { $_.name -eq $node.name }) { $color = "green" }else { $color = "yellow" }
            # $node.attributes.fillcolor = $color
            # $node.attributes.style = "filled"
        }
    }
    Write-PSFMessage "Starting Formatting"
    foreach ($array in $nodeObjectArrays) {
        $array | ForEach-Object { Format-ADADGraphNodeObject -Node $_ }
    }
    foreach ($array in $edgeObjectArrays) {
        $array | ForEach-Object { Format-ADADGraphNodeObject -Edge $_ }
    }

    Invoke-PSFProtectedCommand -ActionString 'New-ADGraphGroupGraph.CreateGraph'  -ActionStringValues $measurement.Count, $allEdgeObjects.count -ScriptBlock {
        $myGraph = (graph -Debug:$false g -Attributes @{overlap = "false"; rankdir = "LR"; charset = "utf-8" } {
                "/* StartObjectDN=$($StartObjectDN -join ";") */"
                foreach ($array in $edgeObjectArrays) {
                    $array | ForEach-Object { edge $_.from -to $_.to -Attributes $_.attributes }
                }
                foreach ($array in $nodeObjectArrays) {
                    $array | ForEach-Object { node $_.name -Attributes $_.attributes }
                }
                # $edgeObjectsFirst | ForEach-Object { edge $_.from -to $_.to -Attributes $_.attributes }
                # $nodeObjectsFirst | ForEach-Object { node $_.name -Attributes $_.attributes }
                # $edgeObjectsSecond | ForEach-Object { edge $_.from -to $_.to -Attributes $_.attributes }
                # $nodeObjectsSecond | ForEach-Object { node $_.name -Attributes $_.attributes }
            } )
        $myGraph | select-object -Unique
    } -PSCmdlet $PSCmdlet  -EnableException $true
}
