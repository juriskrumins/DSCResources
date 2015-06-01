Configuration cDnsServerSecondaryZones {
        param
        (
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable[]]$DnsServerSecondaryZones
        )

        Import-DscResource -ModuleName xDnsServer
        foreach($DnsServerSecondaryZone in $DnsServerSecondaryZones)
        {
            $random=Get-Random
            xDnsServerSecondaryZone "xDnsServerSecondaryZone$random"
            {
                MasterServers = $DnsServerSecondaryZone["MasterServers"]
                Name = $DnsServerSecondaryZone["Name"]
                Ensure = $DnsServerSecondaryZone["Ensure"]
            }
        }
}