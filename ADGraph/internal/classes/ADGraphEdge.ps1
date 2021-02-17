# class definition created by ConvertTo-ClassDefinition at 09/02/2021 12:07:02 for object type PSCustomObject

class ADGraphEdge {
    <#
    .SYNOPSIS
    Simple Class for GraphViz Edges
    #>

    # properties
    [String]$From
    [String]$To
    [System.Collections.Hashtable]$Attributes
    [System.Object]$ToObject
    [System.Object]$FromObject
    [String[]]$SpecialMarkers

    # constructors
    ADGraphEdge () { }
    ADGraphEdge ([PSCustomObject]$InputObject) {
        $this.From = $InputObject.from
        $this.To = $InputObject.to
        $this.Attributes = $InputObject.attributes
        $this.ToObject = $InputObject.toObject
        $this.FromObject = $InputObject.fromObject
        $this.SpecialMarkers=@()
    }
    [String]GetAttrString() {
        return "$($this.From)>>$($this.To)($($this.SpecialMarkers -join "|"))"
    }
}

