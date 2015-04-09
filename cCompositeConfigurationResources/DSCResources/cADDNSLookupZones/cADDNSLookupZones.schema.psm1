Configuration cADDNSLookupZones {
        param
        (
            [parameter(Mandatory=$true)]
            $ADDNSLookupZones,
            [parameter(Mandatory=$true)]
            [string]$ServerName,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cDNSServer

        foreach($DNSZone in $ADDNSLookupZones.keys)
        {
            $random=Get-Random
            switch -exact ($ADDNSLookupZones["$DNSZone"][0])
            {
                "Forward"
                {
                    cADForwardLookupZone "cADForwardLookupZone$random"
                    {
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        Name = $DNSZone
                        ServerName = $ServerName
                    }
                    Break;
                }
                "Reverse"
                {
                    cADReverseLookupZone "cADReverseLookupZone$random"
                    {
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        Name = $DNSZone
                        NetworkId = $ADDNSLookupZones["$DNSZone"][1]
                        ServerName = $ServerName
                    }
                    Break;
                }
            }
        }
}