$Properties = @{
                Name      = New-xDscResourceProperty -Name Name -Type String -Attribute Key `
                                                     -Description 'Name of the forward zone'
                DnsServer = New-xDscResourceProperty -Name MasterServerIPAddress -Type String -Attribute Required `
                                                     -Description 'IP address of primary DNS servers'
                Ensure    = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent' `
                                                     -Description 'Should this resource be present or absent' `
                DomainAdministratorCredential  = New-xDscResourceProperty -Name DomainAdministratorCredential -Type String -Attribute Required `
                                                     -Description 'Credential to create DNS AD forward zone'
                
            }
New-xDscResource -Name CTCO_cADForwardLookupZone -Property $Properties.Values -Path .. -ModuleName cDnsServer -FriendlyName cADForwardLookupZone -Force