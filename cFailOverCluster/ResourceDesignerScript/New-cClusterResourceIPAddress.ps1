Set-Location C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2
$env:PSModulePath="C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\Modules;C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\DSCModules;$env:PSModulePath"
ipmo xDSCResourceDesigner

$resProperties = @{
    Name          = New-xDscResourceProperty -Description 'Name of the WFC cluster role' `
                                             -Name Name -Type String -Attribute Key
    GroupName     = New-xDscResourceProperty -Description 'Name of the WFC cluster reosurce group' `
                                             -Name GroupName -Type String -Attribute Required
    ClusterName   = New-xDscResourceProperty -Description 'Name of the WFC cluster' `
                                             -Name ClusterName -Type String -Attribute Required
    IPAddress     = New-xDscResourceProperty -Description 'IPAddress value' `
                                             -Name IPAddress -Type String -Attribute Required
    SubnetMask    = New-xDscResourceProperty -Description 'SubnetMask value' `
                                             -Name SubnetMask -Type String -Attribute Required
    Owners        = New-xDscResourceProperty -Description 'Resource owners' `
                                             -Name Owners -Type String[] -Attribute Write
    Ensure        = New-xDscResourceProperty -Description 'Whether to create the endpoint or delete it' `
                                             -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent'
    DomainAdministratorCredential = New-xDscResourceProperty -Description 'Credential to create the cluster resource' `
                                             -Name DomainAdministratorCredential -Type String -Attribute Required
}

New-xDscResource -Name CTCO_cClusterResourceIPAddress -Property $resProperties.Values -Path "C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\DSCModules" -ModuleName cFailOverCluster -FriendlyName cClusterResourceIPAddress -Force