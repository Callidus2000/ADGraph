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

}