Configuration cDNSRecords {
        param
        (
            [parameter(Mandatory=$true)]
            $DNSRecords,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -Module xDnsServer

        foreach($DNSRecord in $DNSRecords)
        {
            foreach($Target in $DNSRecord["Target"])
            {
                xDnsRecord "xDnsRecord$(Get-Random)"
                {
                    Name = $DNSRecord["Name"]
                    Target = $Target
                    Type = $DNSRecord["Type"]
                    Zone = $DNSRecord["Zone"]
                    Ensure = $DNSRecord["Ensure"]
                    PsDscRunAsCredential = $DomainAdministratorCredential
                }
            }
        }
}