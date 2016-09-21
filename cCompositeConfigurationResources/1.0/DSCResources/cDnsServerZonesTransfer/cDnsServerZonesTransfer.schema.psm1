Configuration cDnsServerZonesTransfer {
        param
        (
            [parameter(Mandatory=$true)]
            [string[]]$Zones,
            [parameter(Mandatory=$true)]
            [ValidateSet("Any", "Named", "None", "Specific")]
            [string]$Type,
            [parameter(Mandatory=$false)]
            [string[]]$SecondaryServer
        )

        Import-DscResource -ModuleName xDnsServer
        foreach($Zone in $Zones)
        {
            $random=Get-Random
            if($Type -ne "Specific")
            {
                xDnsServerZoneTransfer "xDnsServerZoneTransfer$random"
                {
                    Name = "$Zone"
                    Type = "$Type"
                }
            }
            else
            {
                xDnsServerZoneTransfer "xDnsServerZoneTransfer$random"
                {
                    Name = "$Zone"
                    Type = "$Type"
                    SecondaryServer = $SecondaryServer
                }
            }
        }
}