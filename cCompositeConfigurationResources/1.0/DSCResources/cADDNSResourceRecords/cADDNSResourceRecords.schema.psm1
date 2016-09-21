Configuration cADDNSResourceRecords {
        param
        (
            [parameter(Mandatory=$true)]
            $ADDNSResourceRecords,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential
        )

        Import-DscResource -ModuleName cDNSServer

        foreach($ADDNSResourceRecord in $ADDNSResourceRecords.keys)
        {
            $random=Get-Random
            switch -exact ($ADDNSResourceRecords["$ADDNSResourceRecord"][0])
            {
                "A"
                {
                    cADnsResourceRecord "cADnsResourceRecord$random"
                    {
                        Key = "cADnsResourceRecord$random"
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        RRName = $ADDNSResourceRecords["$ADDNSResourceRecord"][1]
                        RRValue = $ADDNSResourceRecords["$ADDNSResourceRecord"][2]
                        ZoneName = $ADDNSResourceRecords["$ADDNSResourceRecord"][3]
                    }
                    Break;
                }
                "CNAME"
                {
                    cCNAMEDnsResourceRecord "cCNAMEDnsResourceRecord$random"
                    {
                        Key = "cCNAMEDnsResourceRecord$random"
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        RRName = $ADDNSResourceRecords["$ADDNSResourceRecord"][1]
                        RRValue = $ADDNSResourceRecords["$ADDNSResourceRecord"][2]
                        ZoneName = $ADDNSResourceRecords["$ADDNSResourceRecord"][3]
                    }
                    Break;
                }
                "MX"
                {
                    cMXDnsResourceRecord "cMXDnsResourceRecord$random"
                    {
                        Key = "cMXDnsResourceRecord$random"
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        RRName = $ADDNSResourceRecords["$ADDNSResourceRecord"][1]
                        RRValue = $ADDNSResourceRecords["$ADDNSResourceRecord"][2]
                        RRPreference = $ADDNSResourceRecords["$ADDNSResourceRecord"][3]
                        ZoneName = $ADDNSResourceRecords["$ADDNSResourceRecord"][4]
                    }
                    Break;
                }
                "PTR"
                {
                    cPTRDnsResourceRecord "cPTRDnsResourceRecord$random"
                    {
                        Key = "cPTRDnsResourceRecord$random"
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        RRName = $ADDNSResourceRecords["$ADDNSResourceRecord"][1]
                        RRValue = $ADDNSResourceRecords["$ADDNSResourceRecord"][2]
                        ZoneName = $ADDNSResourceRecords["$ADDNSResourceRecord"][3]
                    }
                    Break;
                }
            }
        }
}