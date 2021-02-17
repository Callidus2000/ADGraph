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
                $groups = Import-XLSX -Path $PSScriptRoot\MockingData.xlsx -Sheet "groups"
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
        It "Check Get-ADUser" {
            $allDomains = (get-adforest).domains
            $targetDomain = $allDomains[0]
            $allExistingUsers = Get-ADUser -filter { ( (ObjectClass -eq "user") -and (objectCategory -eq "Person")) } -properties CanonicalName, SamAccountName, Displayname, Description, memberOf, ObjectClass -server $targetDomain

            $allExistingUsers | Should -HaveCount 3
        }
        Describe "Create XLSX Files" {
            It "Create single File for single input" {
                $graphXLSX = New-ADGraph -Domain "myDomain" -DN "CN=joe,OU=Users,DC=mydomain,DC=com" -ReturnType "ExcelFile"
                $graphXLSX|Should -Exist
                #Remove-Item -Path $graphPDF -Force
            }
        }
    }
}