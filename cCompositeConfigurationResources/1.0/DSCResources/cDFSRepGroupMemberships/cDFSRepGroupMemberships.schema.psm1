Configuration cDFSRepGroupMemberships {
        param
        (
            [parameter(Mandatory=$true)]
            $DFSRepGroupMemberships,
            [parameter(Mandatory=$false)]
            [PSCredential]$PsDscRunAsCredential
        )
        
        Import-DscResource -ModuleName cDFS

        foreach($ComputerNAme in $DFSRepGroupMemberships["ComputerNames"])
        {
            cDFSRepGroupMembership "cDFSRepGroupMembership$(Get-Random)"
            {
                ComputerName = $ComputerName
                FolderName = $DFSRepGroupMemberships["FolderName"]
                GroupName = $DFSRepGroupMemberships["GroupName"]
                ContentPath = $DFSRepGroupMemberships["ContentPath"]
                DomainName = $DFSRepGroupMemberships["DomainName"]
                PrimaryMember = $DFSRepGroupMemberships["PrimaryMember"]
                PsDscRunAsCredential = $PsDscRunAsCredential
                ReadOnly = $DFSRepGroupMemberships["ReadOnly"]
                StagingPath = $DFSRepGroupMemberships["StagingPath"]
            }
        }
}