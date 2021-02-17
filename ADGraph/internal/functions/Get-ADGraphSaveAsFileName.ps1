Function Get-ADGraphSaveAsFileName {
    <#
    .SYNOPSIS
    Asks the user for a SaveAs Filename.

    .DESCRIPTION
    Asks the user for a SaveAs Filename.

    .PARAMETER InitialDirectory
    In which directory should the dialog be started?

    .PARAMETER Filter
    File filter, example: "Excel Files (*.xlsx)| *.*"

    .EXAMPLE
    Get-ADGraphSaveAsFileName -InitialDirectory $env:TEMP
    Asks for an Excel filename within the users TEMP directory

    .NOTES
    General notes
    #>
    param(
        [Parameter(Mandatory=$true)]
        $InitialDirectory,
        $Filter="Excel Files (*.xlsx)|*.*"
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $OpenFileDialog.initialDirectory = $InitialDirectory
    $OpenFileDialog.filter = $Filter
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}
