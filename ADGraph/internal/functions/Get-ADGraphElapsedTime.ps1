function Get-ADGraphElapsedTime {
    <#
    .SYNOPSIS
    Time Measurement helper for developing. DEPRECATED.

    .DESCRIPTION
    Queries information from the Active Directory and caches them.

    .PARAMETER Message
    The Message which should be logged

    .EXAMPLE
    Get-ADGraphElapsedTime -Message "Query AD"
    Logs "Query AD" with a timestamp

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    param (
        $Message
    )
    if ($false) {
        if (-not ($global:stopwatch)) {
            Write-PSFMessage -Level Host -Message "Starte Stoppuhr"
            $global:stopwatch = [system.diagnostics.stopwatch]::startNew()
        }
        Write-PSFMessage -Level Host -Message "[$($global:stopwatch.Elapsed.TotalSeconds)]  $Message"
    }
}
