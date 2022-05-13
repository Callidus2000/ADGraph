function Format-ADADGraphNodeObject {
    <#
    .SYNOPSIS
    Performs formatting templates on Edges and Nodes

    .DESCRIPTION
    Performs formatting templates on Edges and Nodes

    .PARAMETER Node
    The ADGraphNode Object to be formatted

    .PARAMETER Edge
    The ADGraphEdge Object to be formatted

    .EXAMPLE
    Format-ADADGraphNodeObject $node
    Formats the $node Object

    .NOTES
    General notes
    #>
    param (
        [ADGraphNode]$Node,
        [ADGraphEdge]$Edge
    )
    if ($Node) {
        $attrString = $node.GetAttrString()
        Write-PSFMessage "Formatting with `$attrString $attrString" -Level Debug
        if ($attrString -match 'ObjectClass=user') {
            $node.attributes.Add("shape", "record")
            $node.nodeType = "User"
            $node.attributes.label = "$($node.attributes.label)|$($node.ADBaseObject.DisplayName)"
        }
        if ($attrString -match '((CN=R-)|(CN=ROL-)).*group') {
            $node.attributes.shape = "cds"
        }
        if ($attrString -match '((CN=ROL)|(CN=DEL))-T[012].*group') {
            $node.attributes.color = "red"
            $node.attributes.penwidth = "4"
        }
        if ($attrString -match 'arrayIndex=0') {
            $node.attributes.fillcolor = "cyan"
            $node.attributes.style = "filled"
        }
        if ($attrString -match 'arrayIndex=1') {
            $node.attributes.fillcolor = "yellow"
            $node.attributes.style = "filled"
        }
        if ($attrString -match 'arrayIndex=2') {
            $node.attributes.fillcolor = "green"
            $node.attributes.style = "filled"
        }
    }
    if ($Edge) {
        $attrString = $Edge.GetAttrString()
        Write-PSFMessage "Formatting with `$attrString $attrString" -Level Debug
        # if ($attrString -match 'ObjectClass=user') {
        #     $node.attributes.Add("shape", "record")
        #     $label = "$($node.attributes.label)|$($node.baseObj.DisplayName)"
        #     $node.nodeType = "User"
        #     $node.attributes.label = "$($node.attributes.label)|$($node.ADBaseObject.DisplayName)"
        # }
        if ($attrString -match '((CN=((ROL)|(DEL))-T[012]).*>>(CN=[DR]-))|((CN=[DR]-).*>>(CN=((ROL)|(DEL))-T[012]))') {
            # Different time epoches
            $Edge.attributes.color = "red"
        }
        # if ($attrString -match '((CN=ROL)|(CN=DEL))-T[012].*group') {
        #     $node.attributes.color = "red"
        #     $node.attributes.penwidth="4"
        # }
    }
}