$global:MockCacheTable = @{}
Describe "Testing Get-Domain" {
    BeforeAll {
        # Define Mock-Functions
        function Mock-GetADForest {
            Write-PSFMessage "Mock-GetADForest called"
            [PSCustomObject]@{
                domains = @("MyFirstDomain", "MySecondDomain")
            }
        }
        function Mock-GetADUser {
            # param($Identity)
            # Write-PSFMessage "Mock-GetADUser called"
            # Write-PSFMessage "Mock-GetADUser called. Identity=$Identity"
            # Write-PSFMessage "Mock-GetADUser called. Filter=$Filter"
            if ($global:MockCacheTable.Contains("users")) {
                $users = $global:MockCacheTable["users"]
            }
            else {
                $users = Import-XLSX -Path "$PSScriptRoot\MockingData.xlsx" -Sheet "user"
                foreach ($user in $users) {
                    $memberOf = $user.memberOf -split ';'
                    $memberOf = $memberOf | ForEach-Object { "CN=$_,OU=groups,DC=mydomain,DC=com" }
                    $user.memberOf = $memberOf
                }
                $global:MockCacheTable.Add("users", $users)
            }
            if ($Identity) {
                $users | Where-Object { $_.DistinguishedName -like "CN=$Identity,*" }
            }
            else {
                $users
            }
        }
        function Mock-GetSingleADUser {
            # param($Identity)
            Write-PSFMessage "Mock-GetSingleADUser called"
            Write-PSFMessage "Mock-GetSingleADUser, Filter=$Identity"
            $allUsers = Mock-GetADUser
            $allUsers | Where-Object { $_.DistinguishedName -like "CN=$Identity,*" }
        }
        function Mock-GetADGroup {
            Write-PSFMessage "Mock-GetADGroup called"
            if ($global:MockCacheTable.Contains("groups")) {
                $global:MockCacheTable["groups"]
            }
            else {
                $groups = Import-XLSX -Path "$PSScriptRoot\MockingData.xlsx" -Sheet "groups"
                foreach ($group in $groups) {
                    $memberOf = $group.memberOf -split ';'
                    $memberOf = $memberOf | ForEach-Object {
                        if (!$_) {}
                        elseif ($_ -like 'CN=*') {
                            $_
                        }
                        else {
                            "CN=$_,OU=groups,DC=mydomain,DC=com"
                        }
                    }
                    $group.memberOf = $memberOf
                    $members = $group.members -split ';'
                    $members = $members | ForEach-Object {
                        if (!$_) {}
                        elseif ($_ -like 'CN=*') {
                            $_
                        }
                        else {
                            "CN=$_,OU=groups,DC=mydomain,DC=com"
                        }
                    }
                    $group.members = $members
                }
                $global:MockCacheTable.Add("groups", $groups)
                $groups
            }
        }
    }
    Context "Mocked all AD Functions" {
        BeforeAll {
            # Perform the real mocking. Each function is mocked twice:
            # -With ModuleName for mocking in internal functions
            # -Without ModuleName for mocking in the pester test itself
            Mock -ModuleName "ADGraph" -CommandName Get-ADForest  -MockWith { Mock-GetADForest }
            Mock -CommandName Get-ADForest  -MockWith { Mock-GetADForest }
            Mock -ModuleName "ADGraph" -CommandName Get-ADUser  -MockWith { Mock-GetADUser }
            Mock -CommandName Get-ADUser  -MockWith { Mock-GetADUser }
            Mock -ModuleName "ADGraph" -CommandName Get-ADGroup -MockWith { Mock-GetADGroup }
            Mock -CommandName Get-ADGroup -MockWith { Mock-GetADGroup }
        }
        It "Check Get-ADForest" {
            $allDomains = (get-adforest).domains
            Write-PSFMessage "$allDomains"
            $allDomains | Should -Contain "MyFirstDomain"
            $allDomains | Should -Contain "MySecondDomain"
            $allDomains | Should -HaveCount 2
        }
        It "Check Get-ADUser" {
            $allDomains = (get-adforest).domains
            $targetDomain = $allDomains[0]
            $allExistingUsers = Get-ADUser -filter { ( (ObjectClass -eq "user") -and (objectCategory -eq "Person")) } -properties CanonicalName, SamAccountName, Displayname, Description, memberOf, ObjectClass -server $targetDomain

            $allExistingUsers | Should -HaveCount 3
        }
        It "Check Get-ADUser with Filter" {
            $joe = Get-ADUser -Identity "joe"

            $joe | Should -HaveCount 1
        }
        It "Check Get-ADGroup with Filter" {
            $allDomains = (get-adforest).domains
            $targetDomain = $allDomains[0]
            $allExistingGroups = Get-ADGroup -filter { (ObjectClass -eq "group") } -properties CanonicalName, SamAccountName, Displayname, Description, memberOf, members, ObjectClass -server $targetDomain

            $allExistingGroups | Should -HaveCount 11
        }
        Describe "New-ADGraph Tests" {
            $testCaseDN = @(
                @{dn = "CN=joe,OU=Users,DC=mydomain,DC=com" }
                @{dn = "CN=jane,OU=Users,DC=mydomain,DC=com" }
                @{dn = "CN=max,OU=Users,DC=mydomain,DC=com" }
                @{dn = "CN=R-sales,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=R-controlling,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=R-admin,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-DCAdmin,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=DEL-T1-SRV123-Admin,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-Intranet,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-CRM,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-SAP,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-SAP-Sales,OU=Groups,DC=mydomain,DC=com" }
                @{dn = "CN=D-SAP-Controlling,OU=Groups,DC=mydomain,DC=com" }
            )
            Describe "SingleGraph for single Input-DNs" {
                It "SingleGraph for Every TestCase-DN should be possible" -TestCases $testCaseDN {
                    # $graph = New-ADGraph -Domain "myDomain" -DN $possibleDNs[0] -ReturnType "SingleGraph"
                    $graph = New-ADGraph -Domain "myDomain" -DN $dn -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Match $dn
                }
                It "Create graph for Joe Pester" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    # $graphString|Set-Clipboard
                    $graphString | Should -Match '"CN=joe,OU=Users,DC=mydomain,DC=com"->"CN=R-sales,OU=groups,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=D-Intranet,OU=groups,DC=mydomain,DC=com"'
                    #Write-PSFMessage "graph for $($startDn): $graph"
                }
                It "Create graph for Jane Pester by direct pipelinining" {
                    $graph = "CN=jane,OU=Users,DC=mydomain,DC=com"| New-ADGraph -Domain "myDomain" -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    # $graphString|Set-Clipboard
                    $graphString | Should -Match '"CN=jane,OU=Users,DC=mydomain,DC=com"->"CN=R-'
                    $graphString | Should -Match '"CN=D-Intranet,OU=groups,DC=mydomain,DC=com"'
                    #Write-PSFMessage "graph for $($startDn): $graph"
                }
                It "Create graph for Jane Pester by Attribute pipelinining" {
                    $graph = Get-ADUser -Identity "jane"| New-ADGraph -Domain "myDomain" -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    # $graphString|Set-Clipboard
                    $graphString | Should -Match '"CN=jane,OU=Users,DC=mydomain,DC=com"->"CN=R-'
                    $graphString | Should -Match '"CN=D-Intranet,OU=groups,DC=mydomain,DC=com"'
                    #Write-PSFMessage "graph for $($startDn): $graph"
                }
                It "Graph contains Starter-Object as comment" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Match '\/* StartObjectDN=CN=joe,OU=Users,DC=mydomain,DC=com'
                }
                It "Graph contains Starter-Object as comment" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Match '\/* StartObjectDN=CN=joe,OU=Users,DC=mydomain,DC=com'
                }
                It "Graph contains No User" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "SingleGraph" -Users $false
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Not -Match '"CN=.*,OU=Users,DC=mydomain,DC=com'
                }
                It "Graph contains No User if started in the middle" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com" -ReturnType "SingleGraph" -Users $false
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Not -Match '"CN=.*,OU=Users,DC=mydomain,DC=com'
                }
                It "Graph contains No User if started in the middle and only Memberof" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com" -ReturnType "SingleGraph" -Members $false
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Not -Match 'CN=joe,OU=Users,DC=mydomain,DC=com'
                    $graphString | Should -Match '"CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com'
                    $graphString | Should -Match '"CN=D-Intranet'
                }
                It "Graph contains Users if started in the middle and only Members are followed" {
                    $graph = New-ADGraph -Domain "myDomain" -DN "CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com" -ReturnType "SingleGraph" -MemberOf $false
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Should -Match 'CN=joe,OU=Users,DC=mydomain,DC=com'
                    $graphString | Should -Match '"CN=R-AllUsers,OU=Groups,DC=mydomain,DC=com'
                    $graphString | Should -Not -Match '"CN=D-Intranet'
                }
            }
            Describe "SingleGraph with multiple DNs as input" {
                It "Create graph for All Three Users" {
                    $distinguishedNames = @("CN=joe,OU=Users,DC=mydomain,DC=com" , "CN=jane,OU=Users,DC=mydomain,DC=com", "CN=max,OU=Users,DC=mydomain,DC=com" )
                    $graph = New-ADGraph -Domain "myDomain" -DN $distinguishedNames -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    # $graphString|Set-Clipboard
                    $graphString | Should -Match '"CN=joe,OU=Users,DC=mydomain,DC=com"->"CN=R-sales,OU=groups,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=D-Intranet,OU=groups,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=jane,OU=Users,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=max,OU=Users,DC=mydomain,DC=com"'
                    Write-PSFMessage "graphString=$graphString"
                    Write-PSFMessage "graphString.count=$(($graphString| select-string -pattern "OU=Users").Count)"
                    # Count occurences of OU=Users within the $graph which is an array
                    [regex]::matches($graph, "OU=Users").count | Should -Be 12
                    #Write-PSFMessage "graph for $($startDn): $graph"
                }
                It "Create graph for Joe and Jane" {
                    $distinguishedNames = @("CN=joe,OU=Users,DC=mydomain,DC=com" , "CN=jane,OU=Users,DC=mydomain,DC=com")
                    $graph = New-ADGraph -Domain "myDomain" -DN $distinguishedNames -ReturnType "SingleGraph"
                    $graph | Should -Not -BeNullOrEmpty
                    $graphString = $graph | Out-String
                    $graphString | Set-Clipboard
                    $graphString | Should -Match '"CN=joe,OU=Users,DC=mydomain,DC=com"->"CN=R-sales,OU=groups,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=D-Intranet,OU=groups,DC=mydomain,DC=com"'
                    $graphString | Should -Match '"CN=jane,OU=Users,DC=mydomain,DC=com"'
                    $graphString | Should -Not -Match '"CN=max,OU=Users,DC=mydomain,DC=com"'
                    Write-PSFMessage "graphString=$graphString"
                    Write-PSFMessage "graphString.count=$(($graphString| select-string -pattern "OU=Users").Count)"
                    # Count occurences of OU=Users within the $graph which is an array
                    [regex]::matches($graph, "OU=Users").count | Should -Be 8
                    [regex]::matches($graph, 'fillcolor="yellow"').Count | Should -Be 4 -Because "Graph contains 4 yellow objects"
                    [regex]::matches($graph, 'fillcolor="cyan"').Count | Should -Be 5 -Because "Graph contains 5 cyan objects"
                    [regex]::matches($graph, 'fillcolor="green"').Count | Should -Be 2 -Because "Graph contains 2 green objects"
                    # ($graph | select-string -pattern 'fillcolor="yellow"').Count | Should -Be 4 -Because "Graph contains 4 yellow objects"
                    # ($graph | select-string -pattern 'fillcolor="cyan"').Count | Should -Be 5 -Because "Graph contains 5 cyan objects"
                    # ($graph | select-string -pattern 'fillcolor="green"').Count | Should -Be 2 -Because "Graph contains 2 green objects"
                    #Write-PSFMessage "graph for $($startDn): $graph"
                }
            }
            Describe "GraphArray with multiple DNs as input" {
                It "Create graph for All Three Users" {
                    $distinguishedNames = @("CN=joe,OU=Users,DC=mydomain,DC=com" , "CN=jane,OU=Users,DC=mydomain,DC=com", "CN=max,OU=Users,DC=mydomain,DC=com" )
                    $global:graphArray = New-ADGraph -Domain "myDomain" -DN $distinguishedNames -ReturnType "GraphArray"
                    # $graphArray|ConvertTo-Json|set-clipboard
                    $graphArray.count | Should -Be 3
                }
            }
        }
        Describe "Create PDF Files" {
            It "Create single File for single input" {
                $graphPDF = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "SinglePDF" -ShowPDF $false #-Path "TestDrive:"
                $graphPDF|Should -Exist
                #Remove-Item -Path $graphPDF -Force
            }
            It "Create multiple Files for multi input" {
                $graphPDF = New-ADGraph -Domain "myDomain" -DN @("CN=jane,OU=Users,DC=mydomain,DC=com","CN=joe,OU=Users,DC=mydomain,DC=com") -ReturnType "SinglePDF" -ShowPDF $false #-Path "TestDrive:"
                $graphPDF | ForEach-Object {$_| Should -Exist}
                #Remove-Item -Path $graphPDF -Force
            }
        }
        It "Interactive Usage" {
            {
                try {
                    Start-ADGraph
                }
                catch {
                    write-psfmessage -level warning "Exception $_"
                    $_
                    throw $_
                }
            } | Should -Not -Throw
        }
    }
}