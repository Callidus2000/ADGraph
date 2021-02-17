Class ADGraphNode {
    <#
    .SYNOPSIS
    Simple Class for GraphViz Nodes
    #>
    [string]$name
    [hashtable]$attributes
    [System.Object]$ADBaseObject
    [string]$nodeType
    [String[]]$SpecialMarkers

    ADGraphNode ([string]$DistinguishedName, [System.Object]$baseObj) {
        $this.name = $DistinguishedName
        $this.ADBaseObject = $baseObj
        $this.attributes = @{ }
        $label = ($DistinguishedName -replace '^CN=(.*?),OU.*$', '$1')
        $this.SpecialMarkers += "ObjectClass=$($baseObj.ObjectClass)"
        $this.attributes.label = $label
    }
    [String]GetAttrString() {
        return "$($this.name)($($this.SpecialMarkers -join "|"))"
    }
}