function Start-ADGraph {
    <#
    .SYNOPSIS
    Starts a simple GUI for creating ADGraphs.

    .DESCRIPTION
    Starts a simple GUI for creating ADGraphs.

    .EXAMPLE
    Start-ADGraph

    Starts the GUI.

    .NOTES
    General notes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]

    param(

    )

    # Which domain should be focused?
    $allDomains = (get-adforest).domains
    # Loop infinitely, script can be closed by clicking cancel on any dialog
    while ($true) {
        $chosenDomain = $allDomains | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.ChooseDomain") -outputmode single
        if ($null -eq $chosenDomain) {
            Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "Domain"
            return
        }
        $allExistingGroupsAndUsers = Get-ADGraphCache -Domain $chosenDomain -ReturnType Array

        $possibleOptions = [ordered] @{
            "Mode: Default"                   = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Mode-Default')
            "Mode: Compare 2 Objects"         = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Mode-Compare-2-Objects')
            "Mode: Multi-Object>One PDF"      = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Mode-Multi-Object-One-PDF')
            "Mode: Multi-Object>Multi-PDF"    = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Mode-Multi-Object-Multi-PDF')
            "Mode: Create Test-XLSX"          = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Mode-Create-Test-XLSX')
            "Option: Visualize MemberOf only" = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Option-Visualize-MemberOf-only')
            "Option: Visualize Members only"  = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Option-Visualize-Members-only')
            "Option: No User"                 = (Get-PSFLocalizedString -Module 'ADGraph' -Name 'Start-ADGraph.OptionGrid.Option-No-User')
        }

        $options = $possibleOptions | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.ChooseOptions") -OutputMode Multiple | Select-Object -ExpandProperty Name
        if ($null -eq $options) {
            Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "Option"
            return
        }
        $newADGraphOptions = @{
            Domain=$chosenDomain
            DistinguishedName = ""
            MemberOf=$true
            Members=$true
            Users             = $true
            ReturnType        = "SinglePDF"
        }
        # Hinterlegung, in welche Richtung Beziehungen nachverfolgt werden sollen
            if ($options.contains("Option: Visualize Members only" )) {
                $newADGraphOptions.MemberOf=$false
            }
            if ($options.contains("Option: Visualize MemberOf only" )) {
                $newADGraphOptions.Members=$false
            }
        if ($options.contains("Option: No User")) {
            $newADGraphOptions.Users = $false
        }
        if ($options.contains("Mode: Compare 2 Objects")) {
            # Vergleichs Verfahren, 2 Startobjekte
            $startObjectFirst = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.CompareFirstObject") -OutputMode Single
            $startObjectSecond = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.CompareSecondObject" ) -OutputMode Single
            if (($null -eq $startObjectFirst) -or ($null -eq $startObjectSecond)) {
                Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "2 Objects"
                return
            }
            $newADGraphOptions.DistinguishedName = @($startObjectFirst.DistinguishedName, $startObjectSecond.DistinguishedName)
            $myGraph = New-ADGraph @newADGraphOptions

            # $fileName = "$($env:temp)\Compare-$($startObjectFirst.DistinguishedName)-with-$($startObjectSecond.DistinguishedName).pdf" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
            # $myGraph | Export-PSGraph -ShowGraph -OutputFormat pdf -DestinationPath $fileName -Debug:$false
        }
        elseif ($options.contains("Mode: Multi-Object>One PDF")) {
            $startObjects = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.CompareXobjects") -OutputMode Multiple | Select-Object -ExpandProperty DistinguishedName
            if (($null -eq $startObjects) ) {
                Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "startObject"
                return
            }
            $newADGraphOptions.DistinguishedName = $startObjects
            $myGraph = New-ADGraph @newADGraphOptions

            # $fileName = "$($env:temp)\Visualize-$($startObjects.count)-objects.pdf"
            # $myGraph | Export-PSGraph -ShowGraph -OutputFormat pdf -DestinationPath $fileName -Debug:$false
        }
        elseif ($options.contains("Mode: Multi-Object>Multi-PDF")) {
            $newADGraphOptions.ReturnType = "MultiPDF"
            # Beliebig viele Startobjekte, das Ergebnis wird in eine PDF je Objekt gepackt
            $startObjectDNs = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.CompareXobjects") -OutputMode Multiple | Select-Object -ExpandProperty DistinguishedName
            if (($null -eq $startObjectDNs) ) {
                Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "startObject"
                return
            }
             $newADGraphOptions.DistinguishedName = $startObjectDNs
            $myGraph = New-ADGraph @newADGraphOptions
            # foreach ($startObjectDN in $startObjects) {
            #     $newADGraphOptions.DistinguishedName = $startObjectDN
            #     $myGraph = New-ADGraph @newADGraphOptions

            #     $fileName = "$($env:temp)\$($startObjectDN).pdf" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
            #     $myGraph | Export-PSGraph -ShowGraph -OutputFormat pdf -DestinationPath $fileName -Debug:$false
            # }
        }
        elseif ($options.contains("Mode: Create Test-XLSX")) {
            $newADGraphOptions.ReturnType = "ExcelFile"
            $startObject = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.ChooseStartobject") -OutputMode Single
            if ($null -eq $startObject) {
                Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "startObject"
                return
            }
            Write-PSFMessage "$($startObject|ConvertTo-Json)"
            $newADGraphOptions.DistinguishedName = $startObject.DistinguishedName
            $myGraph = New-ADGraph @newADGraphOptions
        }
        else {
            # Standard Verfahren, 1 Startobjekt
            $startObject = $allExistingGroupsAndUsers | Select-Object -Property DistinguishedName, DisplayName | Out-GridView -Title (Get-PSFLocalizedString -Module "ADGraph" -Name "Start-ADGraph.ChooseStartobject") -OutputMode Single
            if ($null -eq $startObject) {
                Write-PSFMessage -Level Host -String 'Start-ADGraph.NoInput' -StringValues "startObject"
                return
            }
            $newADGraphOptions.DistinguishedName = $startObject.DistinguishedName
            $myGraph = New-ADGraph @newADGraphOptions
            # $fileName = "$($env:temp)\$($startObject.DistinguishedName).pdf" -replace 'CN=([^,]*),.*?,DC=', '$1-' -replace ',DC=', '.'
            # $myGraph | Export-PSGraph -ShowGraph -OutputFormat pdf -DestinationPath $fileName -Debug:$false
        }
        Write-PSFMessage "myGraph=$myGraph"
        # if ($myGraph) {$myGraph|Set-Clipboard}
    }
}