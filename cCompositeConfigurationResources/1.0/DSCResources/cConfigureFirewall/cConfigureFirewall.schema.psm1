Configuration cConfigureFirewall {
        param
        (
            [parameter(Mandatory=$true)]
            [ValidateSet("False","True")]
            [string]$Enabled,
            [parameter(Mandatory=$true)]
            [ValidateSet("Domain","Private","Public")]
            [string[]]$Profiles,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )
        Import-DscResource -ModuleName cNetworking
        foreach($Profile in $Profiles)
        {
            $ResourceName="cFirewall$($Profile)"
            cFirewall "$ResourceName"
            {
                DomainAdministratorCredential = $DomainAdministratorCredential
                Enabled = $Enabled
                Profile = $Profile
            }
        }
}