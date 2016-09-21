$Global:DSCModuleName   = 'cDFS'
$Global:DSCResourceName = 'BMD_cDFSRepGroupMembership'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $DSCResourceName {
    
        # Create the Mock Objects that will be used for running tests
        $Global:RepGroup = [PSObject]@{
            GroupName = 'Test Group'
            Ensure = 'Present'
            DomainName = 'CONTOSO.COM'
            Description = 'Test Description'
            Members = @('FileServer1','FileServer2')
            Folders = @('Folder1','Folder2')
        }
        $Global:MockRepGroup = [PSObject]@{
            GroupName = $Global:RepGroup.GroupName
            DomainName = $Global:RepGroup.DomainName
            Description = $Global:RepGroup.Description
        }
        $Global:MockRepGroupMember = @(
            [PSObject]@{
                GroupName = $Global:RepGroup.GroupName
                DomainName = $Global:RepGroup.DomainName
                ComputerName = $Global:RepGroup.Members[0]
            },
            [PSObject]@{
                GroupName = $Global:RepGroup.GroupName
                DomainName = $Global:RepGroup.DomainName
                ComputerName = $Global:RepGroup.Members[1]
            }
        )
        $Global:MockRepGroupFolder = @(
            [PSObject]@{
                GroupName = $Global:RepGroup.GroupName
                DomainName = $Global:RepGroup.DomainName
                FolderName = $Global:RepGroup.Folders[0]
                Description = 'Description 1'
                FileNameToExclude = @('~*','*.bak','*.tmp')
                DirectoryNameToExclude = @()
            },
            [PSObject]@{
                GroupName = $Global:RepGroup.GroupName
                DomainName = $Global:RepGroup.DomainName
                FolderName = $Global:RepGroup.Folders[1]
                Description = 'Description 2'
                FileNameToExclude = @('~*','*.bak','*.tmp')
                DirectoryNameToExclude = @()
            }
        )
        $Global:MockRepGroupMembership = [PSObject]@{
            GroupName = $Global:RepGroup.GroupName
            DomainName = $Global:RepGroup.DomainName
            FolderName = $Global:RepGroup.Folders[0]
            ComputerName = $Global:RepGroup.Members[0]
            ContentPath = 'd:\public\software\'
            StagingPath = 'd:\public\software\DfsrPrivate\Staging\'
            ConflictAndDeletedPath = 'd:\public\software\DfsrPrivate\ConflictAndDeleted\'
            ReadOnly = $False
            PrimaryMember = $True
        }
    
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
            Context 'Replication group folder does not exist' {
                
                Mock Get-DfsrMembership
    
                It 'should throw RegGroupFolderMissingError error' {
                    $errorId = 'RegGroupMembershipMissingError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $errorMessage = $($LocalizedData.RepGroupMembershipMissingError) `
                        -f $Global:MockRepGroupMembership.GroupName,$Global:MockRepGroupMembership.FolderName,$Global:MockRepGroupMembership.ComputerName
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null
    
                    {
                        $Result = Get-TargetResource `
                            -GroupName $Global:MockRepGroupMembership.GroupName `
                            -FolderName $Global:MockRepGroupMembership.FolderName `
                            -ComputerName $Global:MockRepGroupMembership.ComputerName
                    } | Should Throw $errorRecord               
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Requested replication group does exist' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return correct replication group' {
                    $Result = Get-TargetResource `
                            -GroupName $Global:MockRepGroupMembership.GroupName `
                            -FolderName $Global:MockRepGroupMembership.FolderName `
                            -ComputerName $Global:MockRepGroupMembership.ComputerName
                    $Result.GroupName | Should Be $Global:MockRepGroupMembership.GroupName
                    $Result.FolderName | Should Be $Global:MockRepGroupMembership.FolderName               
                    $Result.ComputerName | Should Be $Global:MockRepGroupMembership.ComputerName               
                    $Result.ContentPath | Should Be $Global:MockRepGroupMembership.ContentPath               
                    $Result.StagingPath | Should Be $Global:MockRepGroupMembership.StagingPath               
                    $Result.ConflictAndDeletedPath | Should Be $Global:MockRepGroupMembership.ConflictAndDeletedPath               
                    $Result.ReadOnly | Should Be $Global:MockRepGroupMembership.ReadOnly               
                    $Result.PrimaryMember | Should Be $Global:MockRepGroupMembership.PrimaryMember               
                    $Result.DomainName | Should Be $Global:MockRepGroupMembership.DomainName
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource"{
    
            Context 'Replication group folder exists but has different ContentPath' {
                
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.ContentPath = 'Different'
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different StagingPath' {
                
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.StagingPath = 'Different'
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different ReadOnly' {
                
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.ReadOnly = (-not $Splat.ReadOnly)
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different Primary Member' {
                
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.PrimaryMember = (-not $Splat.PrimaryMember)
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
    
            Context 'Replication group membership does not exist' {
                
                Mock Get-DfsrMembership
    
                It 'should throw RegGroupMembershipMissingError error' {
                    $errorId = 'RegGroupMembershipMissingError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $errorMessage = $($LocalizedData.RepGroupMembershipMissingError) -f `
                        $Global:MockRepGroupMembership.GroupName,$Global:MockRepGroupMembership.FolderName,$Global:MockRepGroupMembership.ComputerName
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    { Test-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group membership exists and has no differences' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return true' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group membership exists but has different ContentPath' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.ContentPath = 'Different'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group membership exists but has different StagingPath' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.StagingPath = 'Different'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group membership exists but has different ReadOnly' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.ReadOnly = (-not $Splat.ReadOnly)
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication group membership exists but has different PrimaryMember' {
                
                Mock Get-DfsrMembership -MockWith { return @($Global:MockRepGroupMembership) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupMembership.Clone()
                    $Splat.Remove('ConflictAndDeletedPath')
                    $Splat.PrimaryMember = (-not $Splat.PrimaryMember)
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}