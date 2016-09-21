$Global:DSCModuleName   = 'cDFS'
$Global:DSCResourceName = 'BMD_cDFSRepGroup'

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
            Description = 'Test Description'
            Members = @('FileServer1','FileServer2')
            Folders = @('Folder1','Folder2')
            Topology = 'Manual'
            DomainName = 'CONTOSO.COM'
        }
        $Global:RepGroupConnections = @(
            [PSObject]@{
                GroupName = 'Test Group'
                SourceComputerName = $Global:RepGroup.Members[0]
                DestinationComputerName = $Global:RepGroup.Members[1]
                Ensure = 'Present'
                Description = 'Connection Description'
                DisableConnection = $false
                DisableRDC = $false
                DomainName = 'CONTOSO.COM'
            },
            [PSObject]@{
                GroupName = 'Test Group'
                SourceComputerName = $Global:RepGroup.Members[1]
                DestinationComputerName = $Global:RepGroup.Members[0]
                Ensure = 'Present'
                Description = 'Connection Description'
                DisableConnection = $false
                DisableRDC = $false
                DomainName = 'CONTOSO.COM'
            }
        )
        $Global:RepGroupConnectionDisabled = $Global:RepGroupConnections[0].Clone()
        $Global:RepGroupConnectionDisabled.DisableConnection = $True
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
        $Global:MockRepGroupMembershipNotPrimary = $Global:MockRepGroupMembership.Clone()
        $Global:MockRepGroupMembershipNotPrimary.PrimaryMember = $False
    
        $Global:MockRepGroupConnection = [PSObject]@{
            GroupName = $Global:RepGroupConnections[0].GroupName
            SourceComputerName = $Global:RepGroupConnections[0].SourceComputerName
            DestinationComputerName = $Global:RepGroupConnections[0].DestinationComputerName
            Description = $Global:RepGroupConnections[0].Description
            Enabled = (-not $Global:RepGroupConnections[0].DisableConnection)
            RDCEnabled = (-not $Global:RepGroupConnections[0].DisableRDC)
            DomainName = $Global:RepGroupConnections[0].DomainName
        }
        $Global:RepGroupContentPath = $Global:RepGroup.Clone()
        $Global:RepGroupContentPath += @{ ContentPaths = @($Global:MockRepGroupMembership.ContentPath) }
    
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
            Context 'No replication groups exist' {
                
                Mock Get-DfsReplicationGroup
                Mock Get-DfsrMember
                Mock Get-DfsReplicatedFolder
    
                It 'should return absent replication group' {
                    $Result = Get-TargetResource `
                        -GroupName $Global:RepGroup.GroupName `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Requested replication group does exist' {
                
                Mock Get-DfsReplicationGroup -MockWith { return @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return correct replication group' {
                    $Result = Get-TargetResource `
                        -GroupName $Global:RepGroup.GroupName `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Present'
                    $Result.GroupName | Should Be $Global:RepGroup.GroupName
                    $Result.Description | Should Be $Global:RepGroup.Description
                    $Result.DomainName | Should Be $Global:RepGroup.DomainName
                    $Result.Members | Should Be $Global:RepGroup.Members
                    $Result.Folders | Should Be $Global:RepGroup.Folders
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
    
            Context 'Replication Group does not exist but should' {
                
                Mock Get-DfsReplicationGroup
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 2
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 2
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but has different description' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Description = 'Changed'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but is missing a member' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Members = @('FileServer2','FileServer1','FileServerNew')
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but has an extra member' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Members = @('FileServer2')
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but is missing a folder' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Folders = @('Folder2','Folder1','FolderNew')
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but has an extra folder' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Folders = @('Folder2')
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication Group exists but should not' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists and is correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group with Fullmesh topology exists and is correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[0]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[1]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
                Mock Add-DfsrConnection
                Mock Set-DfsrConnection
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Topology = 'Fullmesh'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                    Assert-MockCalled -commandName Add-DfsrConnection -Exactly 0
                    Assert-MockCalled -commandName Set-DfsrConnection -Exactly 0
                }
            }
    
            Context 'Replication Group with Fullmesh topology exists and has one missing connection' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[1]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
                Mock Add-DfsrConnection
                Mock Set-DfsrConnection
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Topology = 'Fullmesh'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                    Assert-MockCalled -commandName Add-DfsrConnection -Exactly 1
                    Assert-MockCalled -commandName Set-DfsrConnection -Exactly 0
                }
            }
    
            Context 'Replication Group with Fullmesh topology exists and has all connections missing' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
                Mock Add-DfsrConnection
                Mock Set-DfsrConnection
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Topology = 'Fullmesh'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                    Assert-MockCalled -commandName Add-DfsrConnection -Exactly 2
                    Assert-MockCalled -commandName Set-DfsrConnection -Exactly 0
                }
            }
    
            Context 'Replication Group with Fullmesh topology exists and has a disabled connection' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnectionDisabled) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[1]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
                Mock Add-DfsrConnection
                Mock Set-DfsrConnection
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroup.Clone()
                        $Splat.Topology = 'Fullmesh'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                    Assert-MockCalled -commandName Add-DfsrConnection -Exactly 0
                    Assert-MockCalled -commandName Set-DfsrConnection -Exactly 1
                }
            }
    
            Context 'Replication Group Content Path is set but needs to be changed' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembership) }
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroupContentPath.Clone()
                        $Splat.ContentPaths = @('Different')
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication Group Content Path is set and does not need to be changed' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembership) }
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroupContentPath.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 0
                }
            }
    
            Context 'Replication Group Content Path is set and does not need to be changed but primarymember does' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock New-DfsReplicationGroup
                Mock Set-DfsReplicationGroup
                Mock Remove-DfsReplicationGroup
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Add-DfsrMember
                Mock Remove-DfsrMember
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock New-DfsReplicatedFolder
                Mock Remove-DfsReplicatedFolder
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembershipNotPrimary) }
                Mock Set-DfsrMembership
    
                It 'should not throw error' {
                    { 
                        $Splat = $Global:RepGroupContentPath.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Set-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicationGroup -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Add-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName New-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Remove-DfsReplicatedFolder -Exactly 0
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                    Assert-MockCalled -commandName Set-DfsrMembership -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'Replication Group does not exist but should' {
                
                Mock Get-DfsReplicationGroup
                Mock Get-DfsrMember
                Mock Get-DfsReplicatedFolder
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists but has different description' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Description = 'Changed'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                }
            }
    
            Context 'Replication Group exists but is missing a member' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Members = @('FileServer2','FileServer1','FileServerNew')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication Group exists but has an extra member' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Members = @('FileServer2')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication Group exists but is missing a folder' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Folders = @('Folder2','Folder1','FolderNew')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication Group exists but has an extra folder' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Folders = @('Folder2')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
            Context 'Replication Group exists but should not' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 0
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 0
                }
            }
    
            Context 'Replication Group exists and is correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
    
                It 'should return true' {
                    $Splat = $Global:RepGroup.Clone()
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                }
            }
    
            Context 'Replication Group Fullmesh Topology is required and correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[0]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[1]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
    
                It 'should return true' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Topology = 'Fullmesh'
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                }
            }
    
            Context 'Replication Group Fullmesh Topology is required and one connection missing' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[0]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Topology = 'Fullmesh'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                }
            }
    
            Context 'Replication Group Fullmesh Topology is required and all connections missing' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Topology = 'Fullmesh'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                }
            }
    
            Context 'Replication Group Fullmesh Topology is required and connection is disabled' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnectionDisabled) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[0].SourceComputerName }
                Mock Get-DfsrConnection -MockWith { @($Global:RepGroupConnections[1]) } -ParameterFilter { $SourceComputerName -eq $Global:RepGroupConnections[1].SourceComputerName }
    
                It 'should return false' {
                    $Splat = $Global:RepGroup.Clone()
                    $Splat.Topology = 'Fullmesh'
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrConnection -Exactly 2
                }
            }
    
            Context 'Replication Group Content Path is set and different' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembership) }
    
                It 'should return false' {
                    $Splat = $Global:RepGroupContentPath.Clone()
                    $Splat.ContentPaths = @('Different')
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication Group Content Path is set and the same and PrimaryMember is correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembership) }
    
                It 'should return true' {
                    $Splat = $Global:RepGroupContentPath.Clone()
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMembership -Exactly 1
                }
            }
    
            Context 'Replication Group Content Path is set and the same and PrimaryMember is not correct' {
                
                Mock Get-DfsReplicationGroup -MockWith { @($Global:MockRepGroup) }
                Mock Get-DfsrMember -MockWith { return $Global:MockRepGroupMember }
                Mock Get-DfsReplicatedFolder -MockWith { return $Global:MockRepGroupFolder }
                Mock Get-DfsrMembership -MockWith { @($Global:MockRepGroupMembershipNotPrimary) }
    
                It 'should return false' {
                    $Splat = $Global:RepGroupContentPath.Clone()
    
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-DfsReplicationGroup -Exactly 1
                    Assert-MockCalled -commandName Get-DfsrMember -Exactly 1
                    Assert-MockCalled -commandName Get-DfsReplicatedFolder -Exactly 1
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