Configuration cFileACLs {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$FileACLs,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cFile
        foreach($FileACL in $FileACLs)
        {
            $random=Get-Random
            cFileAcl "cFileAcl$random"
            {
                AccessControlType = $FileACL["AccessControlType"]
                DomainAdministratorCredential = $DomainAdministratorCredential
                FileSystemRights = $FileACL["FileSystemRights"]
                Id = "cFileAcl$random"
                IdentityReference = $FileACL["IdentityReference"]
                Path = $FileACL["Path"]
                InheritanceFlags = $FileACL["InheritanceFlags"]
                PropagationFlags = $FileACL["PropagationFlags"]
            }
        }
}