Configuration cClusterComposite {
        param
        (
            [parameter(Mandatory=$true)]
            [boolean]$isClusterPrimaryNode,
            [parameter(Mandatory=$true)]
            [string]$Name,
            [parameter(Mandatory=$true)]
            [string]$StaticIPAddress,
            [parameter(Mandatory=$true)]
            [PSCredential]$DomainAdministratorCredential,
            [parameter(Mandatory=$false)]
            [boolean]$NoStorage=$false,
            [parameter(Mandatory=$false)]
            [uint32]$RetryCount=95,
            [parameter(Mandatory=$false)]
            [uint64]$RetryIntervalSec=5
        )

        Import-DscResource -ModuleName cFailOverCluster


        $random=Get-Random
        switch($isClusterPrimaryNode)
        {
            $true
            {
                cCluster "cCluster$random"
                { 
                    Name = $Name
                    StaticIPAddress = $StaticIPAddress
                    NoStorage = $NoStorage
                    DomainAdministratorCredential = $DomainAdministratorCredential
                }
                cWaitForCluster "cWaitForCluster$random"
                { 
                    Name = $Name
                    RetryCount = $RetryCount
                    RetryIntervalSec = $RetryIntervalSec
                    DependsOn = "[cCluster]cCluster$random"
                }
                Break
            } 
            
            $false
            {
                cWaitForCluster "cWaitForCluster$random"
                { 
                    Name = $Name
                    RetryCount = $RetryCount
                    RetryIntervalSec = $RetryIntervalSec
                } 
                cCluster "cCluster$random"
                { 
                    Name = $Name
                    StaticIPAddress = $StaticIPAddress
                    NoStorage = $NoStorage
                    DomainAdministratorCredential = $DomainAdministratorCredential
                    DependsOn = “[cWaitForCluster]cWaitForCluster$random"
                }
                Break
            }
        }
}
