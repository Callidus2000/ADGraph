Import-Module PSGraph
Import-Module PSFramework

function New-ADGraph {
    <#
    .SYNOPSIS
    Creates a new GraphViz graph for an AD object.

    .DESCRIPTION
    Creates a new GraphViz graph for an AD object.

    .PARAMETER Domain
    Which domain should be inspected? Used as a connection server.

    .PARAMETER DistinguishedName
    The DN of the user or group which should be used as a starting point

    .PARAMETER MemberOf
    Should the memberOf attribute be considered?

    .PARAMETER Members
    Should the members attribute be considered?

    .PARAMETER Users
    Should user objects be included into the graph=

    .PARAMETER ReturnType
    Specifies the return type.

    .PARAMETER Path
    Optional parameter: In which output path should the generated PDF Files be saved? Defaults to the users TEMP directory

    .PARAMETER ShowPDF
    Optional Parameter: If a PDF file is created, should it be directly opened?

    .EXAMPLE
    $graph = Get-ADUser -Identity "jane"| New-ADGraph -Domain "myDomain" -ReturnType "SingleGraph"
    Greates a graph for the user Jane

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Domain,
        [Alias('DN')]
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$DistinguishedName,
        [bool]$MemberOf = $true,
        [bool]$Members = $true,
        [bool]$Users = $true,
        [ValidateSet("SingleGraph", "GraphArray", "SinglePDF", "MultiPDF", "ExcelFile")]
        $ReturnType = "SinglePDF",
        [string]$Path = $env:TEMP,
        [bool]$ShowPDF = $true
    )
    begin {
        Write-PSFMessage "Begin"
        Write-PSFMessage "Begin Domain=$Domain"
        Write-PSFMessage "Begin DistinguishedName=$DistinguishedName"
        $graphOptions = @{
            StartObjectDN = @()
            RemoveUsers   = ($Users -eq $false)
            linkAttribute = @()
        }
        $allExistingGroupsAndUsersHash = Get-ADGraphCache -Domain $Domain -ReturnType HashTable

        $startObjects = @()
    }
    process {
        if ($Verbose) {
            $VerbosePreference = "Continue"
        }
        Write-PSFMessage "PROCESS: DistinguishedName=$DistinguishedName"
        # $graphOptions.StartObjectDN+=$DistinguishedName
        $startObjects += ($DistinguishedName | foreach-object { $allExistingGroupsAndUsersHash[$_] })
    }
    end {
        Write-PSFMessage "End Domain=$Domain"
        Write-PSFMessage "Create $ReturnType for $DistinguishedName"
        # Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"

        Write-PSFMessage "startObjects=$startObjects"
        # In which directions should be searched for relationship?
        if ($Members) {
            $graphOptions.linkAttribute += "members"
        }
        if ($MemberOf) {
            $graphOptions.linkAttribute += "memberOf"
        }
        # Create the graph
        switch ($ReturnType) {
            "SingleGraph" {
                $graphOptions.StartObjectDN = ($startObjects | Select-Object -ExpandProperty DistinguishedName)
                Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"
                $myGraph = New-ADGraphGroupGraph @graphOptions
                return $myGraph | Out-String
            }
            "GraphArray" {
                $graphArray = @()
                foreach ($startObjectDN in ($startObjects | Select-Object -ExpandProperty DistinguishedName) ) {
                    $graphOptions.StartObjectDN = $startObjectDN
                    Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"
                    $graphArray += ((New-ADGraphGroupGraph @graphOptions) | Out-String)
                }
                return $graphArray
            }
            "SinglePDF" {
                $graphOptions.StartObjectDN = ($startObjects | Select-Object -ExpandProperty DistinguishedName)
                Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"
                $myGraph = New-ADGraphGroupGraph @graphOptions
                $DistinguishedNameFileNamePart = ($graphOptions.StartObjectDN -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.') -join "_"
                # $fileName = "$Path\$($graphOptions.StartObjectDN).pdf" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
                $fileName = "$Path\$DistinguishedNameFileNamePart.pdf"
                Write-PSFMessage "SinglePDF, $fileName"
                $myGraph | Export-PSGraph -ShowGraph:$ShowPDF -OutputFormat pdf -DestinationPath $fileName -Debug:$false
                return $fileName
            }
            "MultiPDF" {
                $fileNameArray = @()
                foreach ($startObjectDN in ($startObjects | Select-Object -ExpandProperty DistinguishedName) ) {
                   $graphOptions.StartObjectDN = $startObjectDN
                    Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"
                    $myGraph = New-ADGraphGroupGraph @graphOptions
                    $fileName = "$Path\$startObjectDN.pdf" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
                    $myGraph | Export-PSGraph -ShowGraph:$ShowPDF -OutputFormat pdf -DestinationPath $fileName -Debug:$false
                    $fileNameArray+=$fileName
                }
                return $fileNameArray
            }
            "ExcelFile" {
                $graphOptions.StartObjectDN = ($startObjects | Select-Object -ExpandProperty DistinguishedName)
                Write-PSFMessage "graphOptions=$($graphOptions|ConvertTo-Json)"
                $myGraph = New-ADGraphGroupGraph @graphOptions
                $fileName = "$Path\$($graphOptions.StartObjectDN).xlsx" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
                $myGraph | Out-String | Export-ADGraphExcelFile -Path $fileName
                return $fileName
            }
            Default {}
        }

    }
    #     if ($fileName) {
    #         New-ADGraphExcelFile @graphOptions -Path $fileName
    #     }
}