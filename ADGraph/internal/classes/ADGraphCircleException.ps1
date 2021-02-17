class ADGraphCircleException:System.Exception {
    <#
    .SYNOPSIS
    Simple Class for Circle Exceptions
    #>
    [object[]]$ErrorEdges
    [object[]]$ExistingEdges

    ADGraphCircleException():base() {
        $this::new("Zirkelbezug")
    }

    ADGraphCircleException([string]$mesage):base($mesage) {
        $this.ErrorEdges = @()
        $this.ExistingEdges = @()
    }
    AddErrorEdge($newEdge) {
        $this.ErrorEdges += $newEdge
        $newEdge.attributes.color = "red"
        $newEdge.attributes.penwidth = "4"
    }
    AddExistingEdges($newEdges) {
        $this.ExistingEdges += $newEdges
    }
}