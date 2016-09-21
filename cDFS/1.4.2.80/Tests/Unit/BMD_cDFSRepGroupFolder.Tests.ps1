$Global:DSCModuleName   = 'cDFS'
$Global:DSCResourceName = 'BMD_cDFSRepGroupFolder'

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
                DfsnPath = "\\CONTOSO.COM\Namespace\$($Global:RepGroup.Folders[0])"
            },
            [PSObject]@{
                GroupName = $Global:RepGroup.GroupName
                DomainName = $Global:RepGroup.DomainName
                FolderName = $Global:RepGroup.Folders[1]
                Description = 'Description 2'
                FileNameToExclude = @('~*','*.bak','*.tmp')
                DirectoryNameToExclude = @()
                DfsnPath = "\\CONTOSO.COM\Namespace\$($Global:RepGroup.Folders[1])"
            }
        )
        $Global:MockRepGroupMembership = [PSObject]@{
            GroupName = $Global:RepGroup.GroupName
            DomainName = $Global:RepGroup.DomainName
            FolderName = $Global:RepGroup.Folders[0]
            ComputerName = $Global:RepGroup.ComputerName
            ContentPath = 'd:\public\software\'
            StagingPath = 'd:\public\software\DfsrPrivate\Staging\'
            ConflictAndDeletedPath = 'd:\public\software\DfsrPrivate\ConflictAndDeleted\'
            ReadOnly = $False
        }
    
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
            Context 'Replication group folder does not exist' {
                
                Mock Get-DfsReplicatedFolder
    
                It 'should throw RegGroupFolderMissingError error' {
                    $errorId = 'RegGroupFolderMissingError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $errorMessage = $($LocalizedData.RepGroupFolderMissingError) -f $Global:MockRepGroupFolder[0].GroupName,$Global:MockRepGroupFolder[0].FolderName
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null
    
                    {
                        $Result = Get-TargetResource `
                            -GroupName $Global:MockRepGroupFolder[0].GroupName `
                            -FolderName $Global:MockRepGroupFolder[0].FolderName
                    } | Should Throw $errorRecord               
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Requested replication group does exist' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return correct replication group' {
                    $Result = Get-TargetResource `
                        -GroupName $Global:MockRepGroupFolder[0].GroupName `
                        -FolderName $Global:MockRepGroupFolder[0].FolderName
                    $Result.GroupName | Should Be $Global:MockRepGroupFolder[0].GroupName
                    $Result.FolderName | Should Be $Global:MockRepGroupFolder[0].FolderName               
                    $Result.Description | Should Be $Global:MockRepGroupFolder[0].Description
                    $Result.DomainName | Should Be $Global:MockRepGroupFolder[0].DomainName
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
    
            Context 'Replication group folder exists but has different Description' {
                
                Mock Set-DfsReplicatedFolder
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.Description = 'Different'
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different FileNameToExclude' {
                
                Mock Set-DfsReplicatedFolder
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.FileNameToExclude = @('*.tmp')
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different DirectoryNameToExclude' {
                
                Mock Set-DfsReplicatedFolder
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.DirectoryNameToExclude = @('*.tmp')
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different DfsnPath' {
                
                Mock Set-DfsReplicatedFolder
    
                It 'should not throw error' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.DfsnPath = '\\CONTOSO.COM\Public\Different'
                    { Set-TargetResource @Splat } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Set-DfsReplicatedFolder -Exactly 1
                }
            }
    
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
    
            Context 'Replication group folder does not exist' {
                
                Mock Get-DfsReplicatedFolder
    
                It 'should throw RegGroupFolderMissingError error' {
                    $errorId = 'RegGroupFolderMissingError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $errorMessage = $($LocalizedData.RepGroupFolderMissingError) -f $Global:MockRepGroupFolder[0].GroupName,$Global:MockRepGroupFolder[0].FolderName
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    { Test-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists and has no differences' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return true' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different Description' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.Description = 'Different'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different FileNameToExclude' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.FileNameToExclude = @('*.tmp')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different DirectoryNameToExclude' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.DirectoryNameToExclude = @('*.tmp')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication group folder exists but has different DfsnPath' {
                
                Mock Get-DfsReplicatedFolder -MockWith { return @($Global:MockRepGroupFolder[0]) }
    
                It 'should return false' {
                    $Splat = $Global:MockRepGroupFolder[0].Clone()
                    $Splat.DfsnPath = '\\CONTOSO.COM\Public\Different'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
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
