function Export-ADGraphExcelFile {
    <#
        .SYNOPSIS
        Creates an Excel file from the provided graph.

        .DESCRIPTION
        Creates an Excel file from the provided graph.

        .PARAMETER Graph
        A pregenerated graph

        .PARAMETER Path
        The filename of the to be created Excel file

        .EXAMPLE
        New-ADGraphGroupGraph @graphOptions | Out-String | Export-ADGraphExcelFile -Path $fileName
        Exports the generated graph to the named Excel-File

        .NOTES
        General notes
        #>
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Graph,
        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        $Path
    )
    process {
        Write-PSFMessage "Erstelle $Path  Objekten"
        $Graph |Set-Clipboard
        try {
            $excelContent=@()
            $pattern = 'CN=([^,]*).*>"CN=([^,]*)'
            $results = $Graph | Select-String $pattern -AllMatches
            foreach ($match in $results.Matches) {
                $member = $match.Groups[1]
                $memberOf = $match.Groups[2]
                $excelContent+=[PSCustomObject]@{
                    member = $member
                    memberOf = $memberOf
                }
            }
        }
        catch {
            Write-PSFMessage "Error while extracting Excel-Data"
        }
        $excelContent | Export-Excel -path $Path -WorksheetName "Hierarchy $((Get-Date).toString('yyyy-MM-dd HH-mm'))" -ClearSheet -autosize
        # # Zuordnung aller Node-Objekte zu den Edges
        # $nodeHashTable = @{ }
        # foreach ($node in $nodeObjects) {
        #     $nodeHashTable.add($node.name, $node)
        # }
        # foreach ($edge in $edgeObjects) {
        #     add-member -InputObject $edge -membertype noteproperty -name fromNode -value $nodeHashTable[$edge.from] -Force
        #     add-member -InputObject $edge -membertype noteproperty -name toNode -value $nodeHashTable[$edge.to] -Force
        # }
        # # Es werden nur Objekte als Delegation (daher im AD) angelegt, welche mit einem 't' beginnen
        # $newAdNodes = $nodeObjects | where-object { $_.attributes.label -imatch '^t' }
        # Remove-Item $Path

        # $xlsItems = @()
        # foreach ($entry in $newAdNodes) {
        #     $xlsItems += [PSCustomObject]@{
        #         Name         = $entry.attributes.label
        #         Beschreibung = $entry.ADBaseObject.Description
        #         Insel        = (Get-ADGraphInselFromDN -dn $entry.name)
        #     }
        # }
        # $xlsItems | Export-XLSX  $Path  -WorksheetName "Delegationen"   -AutoFit -Table
        # # Alle Verknüpfungen werden als Delegations-Hierarchie gespeichert
        # $xlsItems = @()
        # foreach ($entry in $edgeObjects) {
        #     $xlsItems += [PSCustomObject]@{
        #         Insel      = (Get-ADGraphInselFromDN -dn $entry.from)
        #         Delegation = ($entry.fromNode.attributes.label)
        #         memberOf   = ($entry.toNode.attributes.label)
        #     }
        # }
        # $xlsItems | Export-XLSX  $Path  -WorksheetName "Delegations-Hierarchie" -AutoFit -Table
    }
}