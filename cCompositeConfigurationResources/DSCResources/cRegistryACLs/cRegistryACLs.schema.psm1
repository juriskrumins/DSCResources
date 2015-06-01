Configuration cRegistryACLs {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$RegistryACLs,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cRegistry
        foreach($RegistryACL in $RegistryACLs)
        {
            $random=Get-Random
            cRegistryAcl "cRegistryAcl$random"
            {
                AccessControlType = $RegistryACL["AccessControlType"]
                DomainAdministratorCredential = $DomainAdministratorCredential
                RegistryRights = $RegistryACL["RegistryRights"]
                Id = "cRegistryAcl$random"
                IdentityReference = $RegistryACL["IdentityReference"]
                Path = $RegistryACL["Path"]
                InheritanceFlags = $RegistryACL["InheritanceFlags"]
                PropagationFlags = $RegistryACL["PropagationFlags"]
            }
        }
}