Set-Location C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2
$env:PSModulePath="C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\Modules;C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\DSCModules;$env:PSModulePath"
ipmo xDSCResourceDesigner

$resProperties = @{
    Name          = New-xDscResourceProperty -Description 'Name of the WFC cluster role' `
                                             -Name Name -Type String -Attribute Key
    ClusterName   = New-xDscResourceProperty -Description 'Name of the WFC cluster' `
                                             -Name ClusterName -Type String -Attribute Required
    Ensure        = New-xDscResourceProperty -Description 'Whether to create the endpoint or delete it' `
                                             -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent'
}

New-xDscResource -Name CTCO_cClusterGroup -Property $resProperties.Values -Path "C:\Users\juris.krumins\Documents\Work\IBANPAY+PSI\PoC\AutomaticDeployment\eco2gadv2\DSCModules" -ModuleName cFailOverCluster -FriendlyName cClusterGroup -Force