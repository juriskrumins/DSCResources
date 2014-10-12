$Properties = @{
                Name      = New-xDscResourceProperty -Name Name -Type String -Attribute Key `
                                                     -Description 'Name of the reverse zone'
                DnsServer = New-xDscResourceProperty -Name ServerName -Type String -Attribute Required `
                                                     -Description 'DNS server name'
                Ensure    = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent' `
                                                     -Description 'Should this resource be present or absent'
                DomainAdministratorCredential  = New-xDscResourceProperty -Name DomainAdministratorCredential -Type String -Attribute Required `
                                                     -Description 'Credential to create DNS AD forward zone'
                NetworkId = New-xDscResourceProperty -Name NetworkId -Type String -Attribute Required `
                                                     -Description 'Specifies a network ID and prefix length for a reverse lookup zone. Use the format A.B.C.D/prefix for IPv4 or 1111:2222:3333:4444::/prefix for IPv6.'
            }
New-xDscResource -Name CTCO_cADReverseLookupZone -Property $Properties.Values -Path .. -ModuleName cDnsServer -FriendlyName cADReverseLookupZone -Force