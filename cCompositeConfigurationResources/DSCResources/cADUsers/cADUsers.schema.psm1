Configuration cADUsers {
        param
        (
            [parameter(Mandatory=$true)]
            [string[]]$UserNames,
            [parameter(Mandatory=$true)]
            [string]$DomainName,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential,
            [parameter(Mandatory=$true)]
            [PSCredential]$Password
        )

        Import-DscResource -ModuleName cActiveDirectory

        foreach($UserName in $UserNames)
        {
            $random=Get-Random
            cADUser "User$random"
            {
                DomainAdministratorCredential = $DomainAdministratorCredential
                DomainName = $DomainName
                UserName = $UserName
                Password = $Password
            }
        }
}