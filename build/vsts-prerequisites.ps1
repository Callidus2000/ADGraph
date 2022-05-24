param (
    [string]
    $Repository = 'PSGallery'
)

$modules = @("Pester", "PSFramework", "PSModuleDevelopment", "PSScriptAnalyzer")
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature
# Automatically add missing dependencies
$data = Import-PowerShellDataFile -Path "$PSScriptRoot\..\ADGraph\ADGraph.psd1"
foreach ($dependency in $data.RequiredModules | Where-Object ModuleName -notin @('ActiveDirectory')) {
    if ($dependency -is [string]) {
        if ($modules -contains $dependency) { continue }
        $modules += $dependency
    }
    else {
        if ($modules -contains $dependency.ModuleName) { continue }
        $modules += $dependency.ModuleName
    }
}

foreach ($module in $modules) {
    Write-Host "Installing $module" -ForegroundColor Cyan
    Install-Module $module -Force -SkipPublisherCheck -Repository $Repository
    Import-Module $module -Force -PassThru
}